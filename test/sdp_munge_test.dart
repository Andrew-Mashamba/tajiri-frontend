import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/services/call_webrtc_service.dart';

void main() {
  // Actual Android SDP captured from device logs
  const androidSdp = 'v=0\r\n'
      'o=- 4843880947723384246 2 IN IP4 127.0.0.1\r\n'
      's=-\r\n'
      't=0 0\r\n'
      'a=group:BUNDLE 0 1\r\n'
      'a=extmap-allow-mixed\r\n'
      'a=msid-semantic: WMS e589c487-af3f-492d-9a0b-d15681d5a5ae\r\n'
      'm=audio 9 UDP/TLS/RTP/SAVPF 111 63 9 102 0 8 13 110 126\r\n'
      'c=IN IP4 0.0.0.0\r\n'
      'a=rtcp:9 IN IP4 0.0.0.0\r\n'
      'a=ice-ufrag:jHpn\r\n'
      'a=ice-pwd:mkIxVRfuWj7b1ezi0FTeggHR\r\n'
      'a=ice-options:trickle renomination\r\n'
      'a=fingerprint:sha-256 97:65:B1:56:1B:C6:A0:CC:AC:D3:C7:F7:1B:BD:24:22:48:0F:F3:1B:44:FD:37:D1:89:A4:C1:19:DF:A8:26:1A\r\n'
      'a=setup:actpass\r\n'
      'a=mid:0\r\n'
      'a=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level\r\n'
      'a=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time\r\n'
      'a=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01\r\n'
      'a=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid\r\n'
      'a=sendrecv\r\n'
      'a=msid:e589c487-af3f-492d-9a0b-d15681d5a5ae 68230ba0-4bc7-4a4c-a4d0-a82677c5ccb6\r\n'
      'a=rtcp-mux\r\n'
      'a=rtpmap:111 opus/48000/2\r\n'
      'a=rtcp-fb:111 transport-cc\r\n'
      'a=fmtp:111 minptime=10;useinbandfec=1\r\n'
      'a=rtpmap:63 red/48000/2\r\n'
      'a=fmtp:63 111/111\r\n'
      'a=rtpmap:9 G722/8000\r\n'
      'a=rtpmap:102 ILBC/8000\r\n'
      'a=rtpmap:0 PCMU/8000\r\n'
      'a=rtpmap:8 PCMA/8000\r\n'
      'a=rtpmap:13 CN/8000\r\n'
      'a=rtpmap:110 telephone-event/48000\r\n'
      'a=rtpmap:126 telephone-event/8000\r\n'
      'a=ssrc:2395480282 cname:6Zm3wYFo50wA7RYc\r\n'
      'a=ssrc:2395480282 msid:e589c487-af3f-492d-9a0b-d15681d5a5ae 68230ba0-4bc7-4a4c-a4d0-a82677c5ccb6\r\n'
      'm=video 9 UDP/TLS/RTP/SAVPF 96 97 98 99 35 36 37 38 39 40 41 42 127 103 104 105 106 107 108 45\r\n'
      'c=IN IP4 0.0.0.0\r\n'
      'a=rtcp:9 IN IP4 0.0.0.0\r\n'
      'a=ice-ufrag:jHpn\r\n'
      'a=ice-pwd:mkIxVRfuWj7b1ezi0FTeggHR\r\n'
      'a=ice-options:trickle renomination\r\n'
      'a=fingerprint:sha-256 97:65:B1:56:1B:C6:A0:CC:AC:D3:C7:F7:1B:BD:24:22:48:0F:F3:1B:44:FD:37:D1:89:A4:C1:19:DF:A8:26:1A\r\n'
      'a=setup:actpass\r\n'
      'a=mid:1\r\n'
      'a=extmap:14 urn:ietf:params:rtp-hdrext:toffset\r\n'
      'a=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time\r\n'
      'a=extmap:13 urn:3gpp:video-orientation\r\n'
      'a=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01\r\n'
      'a=extmap:5 http://www.webrtc.org/experiments/rtp-hdrext/playout-delay\r\n'
      'a=extmap:6 http://www.webrtc.org/experiments/rtp-hdrext/video-content-type\r\n'
      'a=extmap:7 http://www.webrtc.org/experiments/rtp-hdrext/video-timing\r\n'
      'a=extmap:8 http://www.webrtc.org/experiments/rtp-hdrext/color-space\r\n'
      'a=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid\r\n'
      'a=extmap:10 urn:ietf:params:rtp-hdrext:sdes:rtp-stream-id\r\n'
      'a=extmap:11 urn:ietf:params:rtp-hdrext:sdes:repaired-rtp-stream-id\r\n'
      'a=recvonly\r\n'
      'a=rtcp-mux\r\n'
      'a=rtcp-rsize\r\n'
      'a=rtpmap:96 VP8/90000\r\n'
      'a=rtcp-fb:96 goog-remb\r\n'
      'a=rtcp-fb:96 transport-cc\r\n'
      'a=rtcp-fb:96 ccm fir\r\n'
      'a=rtcp-fb:96 nack\r\n'
      'a=rtcp-fb:96 nack pli\r\n'
      'a=rtpmap:97 rtx/90000\r\n'
      'a=fmtp:97 apt=96\r\n'
      'a=rtpmap:98 VP9/90000\r\n'
      'a=rtcp-fb:98 goog-remb\r\n'
      'a=rtcp-fb:98 transport-cc\r\n'
      'a=rtcp-fb:98 ccm fir\r\n'
      'a=rtcp-fb:98 nack\r\n'
      'a=rtcp-fb:98 nack pli\r\n'
      'a=fmtp:98 profile-id=0\r\n'
      'a=rtpmap:99 rtx/90000\r\n'
      'a=fmtp:99 apt=98\r\n'
      'a=rtpmap:35 VP9/90000\r\n'
      'a=rtcp-fb:35 goog-remb\r\n'
      'a=rtcp-fb:35 transport-cc\r\n'
      'a=rtcp-fb:35 ccm fir\r\n'
      'a=rtcp-fb:35 nack\r\n'
      'a=rtcp-fb:35 nack pli\r\n'
      'a=fmtp:35 profile-id=1\r\n'
      'a=rtpmap:36 rtx/90000\r\n'
      'a=fmtp:36 apt=35\r\n'
      'a=rtpmap:37 VP9/90000\r\n'
      'a=rtcp-fb:37 goog-remb\r\n'
      'a=rtcp-fb:37 transport-cc\r\n'
      'a=rtcp-fb:37 ccm fir\r\n'
      'a=rtcp-fb:37 nack\r\n'
      'a=rtcp-fb:37 nack pli\r\n'
      'a=fmtp:37 profile-id=3\r\n'
      'a=rtpmap:38 rtx/90000\r\n'
      'a=fmtp:38 apt=37\r\n'
      'a=rtpmap:39 AV1/90000\r\n'
      'a=rtcp-fb:39 goog-remb\r\n'
      'a=rtcp-fb:39 transport-cc\r\n'
      'a=rtcp-fb:39 ccm fir\r\n'
      'a=rtcp-fb:39 nack\r\n'
      'a=rtcp-fb:39 nack pli\r\n'
      'a=fmtp:39 level-idx=5;profile=0;tier=0\r\n'
      'a=rtpmap:40 rtx/90000\r\n'
      'a=fmtp:40 apt=39\r\n'
      'a=rtpmap:41 AV1/90000\r\n'
      'a=rtcp-fb:41 goog-remb\r\n'
      'a=rtcp-fb:41 transport-cc\r\n'
      'a=rtcp-fb:41 ccm fir\r\n'
      'a=rtcp-fb:41 nack\r\n'
      'a=rtcp-fb:41 nack pli\r\n'
      'a=fmtp:41 level-idx=5;profile=1;tier=0\r\n'
      'a=rtpmap:42 rtx/90000\r\n'
      'a=fmtp:42 apt=41\r\n'
      'a=rtpmap:127 H264/90000\r\n'
      'a=rtcp-fb:127 goog-remb\r\n'
      'a=rtcp-fb:127 transport-cc\r\n'
      'a=rtcp-fb:127 ccm fir\r\n'
      'a=rtcp-fb:127 nack\r\n'
      'a=rtcp-fb:127 nack pli\r\n'
      'a=fmtp:127 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42e01f\r\n'
      'a=rtpmap:103 rtx/90000\r\n'
      'a=fmtp:103 apt=127\r\n'
      'a=rtpmap:104 H265/90000\r\n'
      'a=rtcp-fb:104 goog-remb\r\n'
      'a=rtcp-fb:104 transport-cc\r\n'
      'a=rtcp-fb:104 ccm fir\r\n'
      'a=rtcp-fb:104 nack\r\n'
      'a=rtcp-fb:104 nack pli\r\n'
      'a=rtpmap:105 rtx/90000\r\n'
      'a=fmtp:105 apt=104\r\n'
      'a=rtpmap:106 red/90000\r\n'
      'a=rtpmap:107 rtx/90000\r\n'
      'a=fmtp:107 apt=106\r\n'
      'a=rtpmap:108 ulpfec/90000\r\n'
      'a=rtpmap:45 flexfec-03/90000\r\n'
      'a=rtcp-fb:45 goog-remb\r\n'
      'a=rtcp-fb:45 transport-cc\r\n'
      'a=fmtp:45 repair-window=10000000\r\n';

  test('strips only H265 and ensures trailing CRLF', () {
    final sdpMap = {'type': 'offer', 'sdp': androidSdp};
    final extracted = CallWebRTCService.extractSdp(sdpMap);
    final munged = extracted.sdp;

    // Should NOT contain H265 codec lines (only codec iOS doesn't support)
    expect(munged.contains('H265'), false, reason: 'H265 codec should be removed');
    expect(munged.contains('a=rtpmap:104 '), false, reason: 'PT 104 rtpmap should be removed');
    expect(munged.contains('a=rtcp-fb:104 '), false, reason: 'PT 104 rtcp-fb should be removed');
    expect(munged.contains('a=fmtp:105 apt=104'), false, reason: 'PT 105 RTX for H265 should be removed');

    // m=video line should NOT contain H265 PTs
    final mVideoLine = munged.split('\r\n').firstWhere((l) => l.startsWith('m=video'));
    expect(mVideoLine.contains(' 104 '), false, reason: 'PT 104 should be removed from m=video');
    expect(mVideoLine.contains(' 105 '), false, reason: 'PT 105 should be removed from m=video');

    // Should STILL contain AV1, flexfec-03, extmap-allow-mixed, renomination (iOS supports these)
    expect(munged.contains('AV1'), true, reason: 'AV1 should be preserved (iOS supports it)');
    expect(munged.contains('flexfec-03'), true, reason: 'flexfec-03 should be preserved');
    expect(munged.contains('a=extmap-allow-mixed'), true, reason: 'extmap-allow-mixed should be preserved');
    expect(munged.contains('renomination'), true, reason: 'renomination should be preserved');

    // Should contain supported codecs
    expect(munged.contains('a=rtpmap:96 VP8/90000'), true, reason: 'VP8 should be preserved');
    expect(munged.contains('a=rtpmap:98 VP9/90000'), true, reason: 'VP9 should be preserved');
    expect(munged.contains('a=rtpmap:127 H264/90000'), true, reason: 'H264 should be preserved');
    expect(munged.contains('a=rtpmap:111 opus/48000/2'), true, reason: 'opus should be preserved');

    // Audio section should be completely untouched
    final mAudioLine = munged.split('\r\n').firstWhere((l) => l.startsWith('m=audio'));
    expect(mAudioLine, 'm=audio 9 UDP/TLS/RTP/SAVPF 111 63 9 102 0 8 13 110 126',
        reason: 'Audio m= line should be untouched');

    // SDP must end with \r\n (critical for iOS parser)
    expect(munged.endsWith('\r\n'), true, reason: 'SDP must end with CRLF');

    // SDP should still start with v=0
    expect(munged.startsWith('v=0\r\n'), true);

    print('Original SDP: ${androidSdp.length} bytes');
    print('Munged SDP:   ${munged.length} bytes');
    print('m=video (munged): $mVideoLine');
  });

  test('extractSdp preserves SDP when no unsupported codecs present', () {
    // Simple SDP with only standard codecs
    const simpleSdp = 'v=0\r\n'
        'o=- 123 2 IN IP4 127.0.0.1\r\n'
        's=-\r\n'
        't=0 0\r\n'
        'm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'
        'a=rtpmap:111 opus/48000/2\r\n';

    final sdpMap = {'type': 'offer', 'sdp': simpleSdp};
    final extracted = CallWebRTCService.extractSdp(sdpMap);
    expect(extracted.sdp, simpleSdp);
    expect(extracted.type, 'offer');
  });

  test('munged SDP has valid structure (no empty m= lines)', () {
    final sdpMap = {'type': 'offer', 'sdp': androidSdp};
    final extracted = CallWebRTCService.extractSdp(sdpMap);
    final lines = extracted.sdp.split('\r\n');

    // Every m= line should have at least one payload type
    for (final line in lines) {
      if (line.startsWith('m=')) {
        final parts = line.split(' ');
        expect(parts.length, greaterThan(3),
            reason: 'm= line should have proto + at least 1 PT: $line');
      }
    }

    // No consecutive \r\n\r\n (empty lines)
    expect(extracted.sdp.contains('\r\n\r\n'), false,
        reason: 'Should not have empty lines in SDP');
  });
}
