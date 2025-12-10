import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:crypto/crypto.dart';
import 'package:interskwela/widgets/meeting/meeting_widgets.dart';

class MeetingScreen extends StatefulWidget {
  final String classCode;
  final String username;
  final String role;

  const MeetingScreen({
    required this.classCode,
    required this.username,
    required this.role,
    super.key,
  });

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  String _message = 'Ready to join the meeting';

  // Video state
  int? _remoteUid;
  int? _localUid;
  bool _isJoined = false;
  RtcEngine? _engine;

  // Control state
  bool _isMicMuted = false;
  bool _isCameraMuted = false;
  bool _isScreenSharing = false;

  // UID to username mapping for remote participants
  final Map<int, String> _remoteUsers = {};

  @override
  void initState() {
    super.initState();
    _loadEnv();
    _localUid = _generateConsistentUid();
  }

  int _generateConsistentUid() {
    final bytes = utf8.encode(widget.username);
    final digest = sha256.convert(bytes);
    final uint8List = Uint8List.fromList(digest.bytes);
    return ByteData.sublistView(uint8List, 0, 4).getInt32(0).abs();
  }

  Future<void> _loadEnv() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");
  }

  /// Register this user in the meeting room
  Future<void> _registerUser() async {
    try {
      await http.post(
        Uri.parse("${dotenv.env['SERVER_URL']}/api/meeting"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'action': 'register',
          'channelName': widget.classCode,
          'uid': _localUid,
          'username': widget.username,
          'role': widget.role,
        }),
      );
    } catch (e) {
      debugPrint('Failed to register user: $e');
    }
  }

  /// Fetch username for a remote user by UID
  Future<String> _fetchRemoteUsername(int uid) async {
    try {
      final response = await http.post(
        Uri.parse("${dotenv.env['SERVER_URL']}/api/meeting"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'action': 'get-user',
          'channelName': widget.classCode,
          'uid': uid,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['username'] ?? 'Participant';
      }
    } catch (e) {
      debugPrint('Failed to fetch remote username: $e');
    }
    return 'Participant';
  }

  /// Unregister this user when leaving
  Future<void> _unregisterUser() async {
    try {
      await http.post(
        Uri.parse("${dotenv.env['SERVER_URL']}/api/meeting"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'action': 'unregister',
          'channelName': widget.classCode,
          'uid': _localUid,
        }),
      );
    } catch (e) {
      debugPrint('Failed to unregister user: $e');
    }
  }

  Future<Map<String, dynamic>?> _fetchToken() async {
    setState(() {
      _message = 'Connecting to server...';
    });

    try {
      final response = await http.post(
        Uri.parse("${dotenv.env['SERVER_URL']}/api/generateToken"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'channelName': widget.classCode,
          'uid': _localUid,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        setState(() {
          _message = 'Failed to connect: ${response.statusCode} ';
        });
        return null;
      }
    } catch (e) {
      setState(() {
        _message = 'Network error. Please check your connection.';
      });
      return null;
    }
  }

  Future<void> _joinChannel() async {
    final data = await _fetchToken();
    if (data == null) return;

    setState(() {
      _message = 'Initializing video...';
    });

    final String token = data['token'];
    final String appId = data['appId'];

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(appId: appId));

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined: (connection, remoteUid, elapsed) async {
          // Fetch the username for this remote user
          final username = await _fetchRemoteUsername(remoteUid);
          setState(() {
            _remoteUid = remoteUid;
            _remoteUsers[remoteUid] = username;
            _message = '$username joined';
          });
        },
        onUserOffline: (connection, remoteUid, reason) {
          final username = _remoteUsers[remoteUid] ?? 'Participant';
          setState(() {
            _remoteUsers.remove(remoteUid);
            _remoteUid = null;
            _message = '$username left the meeting';
          });
        },
        onJoinChannelSuccess: (connection, elapsed) {
          // Register this user so others can see their name
          _registerUser();
          setState(() {
            _isJoined = true;
            _message = 'Connected to ${widget.classCode}';
          });
        },
        onError: (err, msg) {
          setState(() {
            _message = 'Connection error occurred';
          });
        },
      ),
    );

    await _engine!.enableVideo();
    await _engine!.setChannelProfile(
      ChannelProfileType.channelProfileLiveBroadcasting,
    );

    await _engine!.setClientRole(
      role: ClientRoleType.clientRoleBroadcaster,
      options: null,
    );

    await _engine!.startPreview();

    await _engine!.joinChannel(
      token: token,
      channelId: widget.classCode,
      uid: _localUid!,
      options: ChannelMediaOptions(
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  Future<void> _leaveChannel() async {
    // Unregister this user from the meeting
    await _unregisterUser();

    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
    }
    setState(() {
      _isJoined = false;
      _remoteUid = null;
      _remoteUsers.clear();
      _message = 'Left the meeting';
    });
  }

  void _toggleMic() {
    setState(() {
      _isMicMuted = !_isMicMuted;
    });
    _engine?.muteLocalAudioStream(_isMicMuted);
  }

  void _toggleCamera() {
    setState(() {
      _isCameraMuted = !_isCameraMuted;
    });
    _engine?.muteLocalVideoStream(_isCameraMuted);
  }

  void _toggleScreenShare() {
    setState(() {
      _isScreenSharing = !_isScreenSharing;
    });
    // Screen sharing logic would go here
  }

  @override
  void dispose() {
    _leaveChannel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MeetingTheme.backgroundColor,
      body: Column(
        children: [
          // Top header
          MeetingHeader(
            meetingCode: widget.classCode,
            meetingTitle: 'Class: ${widget.classCode}',
            onBack: () {
              if (_isJoined) {
                _showLeaveConfirmation();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),

          // Status bar
          _buildStatusBar(),

          // Main content area
          Expanded(
            child: _isJoined ? _buildVideoArea() : _buildWelcomeScreen(),
          ),

          // Page indicator
          if (_isJoined) const PageIndicator(pageCount: 1, currentPage: 0),

          // Bottom control bar
          MeetingControlBar(
            isMicMuted: _isMicMuted,
            isCameraMuted: _isCameraMuted,
            isScreenSharing: _isScreenSharing,
            isJoined: _isJoined,
            onMicToggle: _toggleMic,
            onCameraToggle: _toggleCamera,
            onScreenShare: _toggleScreenShare,
            onLeave: _leaveChannel,
            onJoin: _joinChannel,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(
        _message,
        style: TextStyle(color: MeetingTheme.secondaryTextColor, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return MeetingWelcomeScreen(classCode: widget.classCode, message: _message);
  }

  Widget _buildVideoArea() {
    final List<VideoTileCard> tiles = [];

    // Add local video tile
    if (widget.role == 'teacher' || !_isCameraMuted) {
      tiles.add(
        VideoTileCard(
          participantName: widget.username,
          isLocal: true,
          isMuted: _isMicMuted,
          videoWidget: _engine != null
              ? AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine!,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                )
              : null,
        ),
      );
    }

    // Add remote video tile
    if (_remoteUid != null) {
      tiles.add(
        VideoTileCard(
          participantName: _remoteUsers[_remoteUid] ?? 'Participant',
          isActiveSpeaker: true,
          videoWidget: _engine != null
              ? AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _engine!,
                    canvas: VideoCanvas(uid: _remoteUid),
                    connection: RtcConnection(channelId: widget.classCode),
                  ),
                )
              : null,
        ),
      );
    }

    // If no tiles, show waiting message
    if (tiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam_outlined,
              size: 64,
              color: Colors.white38,
            ),
            const SizedBox(height: 16),
            Text(
              'Waiting for participants...',
              style: TextStyle(
                color: MeetingTheme.secondaryTextColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return VideoGrid(tiles: tiles);
  }

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MeetingTheme.surfaceColor,
        title: const Text(
          'Leave Meeting?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to leave this meeting?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: MeetingTheme.secondaryTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveChannel();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MeetingTheme.leaveButtonColor,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}
