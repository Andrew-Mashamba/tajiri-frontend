// lib/ambulance/pages/first_aid_guide_page.dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import '../../services/local_storage_service.dart';
import '../models/ambulance_models.dart';
import '../services/ambulance_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kRed = Color(0xFFCC0000);

class FirstAidGuidePage extends StatefulWidget {
  const FirstAidGuidePage({super.key});
  @override
  State<FirstAidGuidePage> createState() => _FirstAidGuidePageState();
}

class _FirstAidGuidePageState extends State<FirstAidGuidePage>
    with SingleTickerProviderStateMixin {
  final AmbulanceService _service = AmbulanceService();
  List<FirstAidGuide> _guides = [];
  bool _isLoading = true;
  int? _expandedId;
  late final bool _isSwahili;
  late final TabController _tabCtrl;

  // FEATURE 34: Audio player
  AudioPlayer? _audioPlayer;
  int? _playingAudioId;
  bool _isAudioPlaying = false;

  // FEATURE 37: Video controllers mapped by guide id
  final Map<int, VideoPlayerController> _videoControllers = {};

  static const _categories = [
    ('all', 'All', 'Zote', Icons.grid_view_rounded),
    ('cpr', 'CPR', 'CPR', Icons.favorite_rounded),
    ('choking', 'Choking', 'Kukosa Pumzi', Icons.do_not_touch_rounded),
    ('bleeding', 'Bleeding', 'Kutoka Damu', Icons.water_drop_rounded),
    ('burns', 'Burns', 'Kuungua', Icons.local_fire_department_rounded),
    ('fractures', 'Fractures', 'Kuvunjika', Icons.accessibility_new_rounded),
    ('snakebite', 'Snakebite', 'Kuumwa na Nyoka', Icons.pest_control_rounded),
    ('drowning', 'Drowning', 'Kuzama', Icons.pool_rounded),
    ('pediatric', 'Pediatric', 'Watoto', Icons.child_care_rounded),
  ];

  // Fallback offline guides
  static const _offlineGuides = [
    {
      'id': 901,
      'title': 'CPR - Cardiopulmonary Resuscitation',
      'title_sw': 'CPR - Ufufuaji wa Moyo na Mapafu',
      'category': 'cpr',
      'content':
          'CPR is a lifesaving technique used when someone\'s heart stops beating.',
      'content_sw':
          'CPR ni mbinu ya kuokoa maisha inayotumika wakati moyo wa mtu unasimama kupiga.',
      'steps': [
        'Check responsiveness - tap and shout',
        'Call emergency services',
        'Place heel of hand on center of chest',
        'Push hard and fast - 30 compressions',
        'Give 2 rescue breaths',
        'Repeat until help arrives'
      ],
      'steps_sw': [
        'Angalia kama mtu ana fahamu - gonga na piga kelele',
        'Piga simu ya dharura',
        'Weka kisigino cha mkono katikati ya kifua',
        'Bonyeza kwa nguvu na haraka - mara 30',
        'Toa pumzi 2 za kuokoa',
        'Rudia hadi msaada ufike'
      ],
    },
    {
      'id': 902,
      'title': 'Choking - Adult',
      'title_sw': 'Kukosa Pumzi - Mtu Mzima',
      'category': 'choking',
      'content':
          'Choking occurs when a foreign object blocks the throat or windpipe.',
      'content_sw':
          'Kukosa pumzi hutokea wakati kitu kigeni kinazuia koo au bomba la pumzi.',
      'steps': [
        'Ask "Are you choking?"',
        'Give 5 back blows between shoulder blades',
        'Give 5 abdominal thrusts (Heimlich)',
        'Alternate between back blows and thrusts',
        'If unconscious, begin CPR'
      ],
      'steps_sw': [
        'Uliza "Unakosa pumzi?"',
        'Piga mgongoni mara 5 kati ya mabega',
        'Bonyeza tumbo mara 5 (Heimlich)',
        'Badilisha kati ya kupiga mgongoni na kubonyeza',
        'Kama amepoteza fahamu, anza CPR'
      ],
    },
    {
      'id': 903,
      'title': 'Severe Bleeding',
      'title_sw': 'Kutoka Damu Kwa Wingi',
      'category': 'bleeding',
      'content':
          'Severe bleeding can be life-threatening and requires immediate action.',
      'content_sw':
          'Kutoka damu kwa wingi kunaweza kuhatarisha maisha na kunahitaji hatua za haraka.',
      'steps': [
        'Apply direct pressure with clean cloth',
        'Keep pressure for at least 15 minutes',
        'If blood soaks through, add more cloth on top',
        'Elevate the injured area above heart level',
        'Apply tourniquet only as last resort',
        'Call emergency services'
      ],
      'steps_sw': [
        'Bonyeza moja kwa moja kwa kitambaa safi',
        'Endelea kubonyeza kwa dakika 15 angalau',
        'Kama damu inapita, ongeza kitambaa juu',
        'Inua eneo lililoumia juu ya kiwango cha moyo',
        'Tumia tourniquet kama njia ya mwisho tu',
        'Piga simu ya dharura'
      ],
    },
    {
      'id': 904,
      'title': 'Burns Treatment',
      'title_sw': 'Matibabu ya Kuungua',
      'category': 'burns',
      'content': 'Burns require immediate cooling to minimize tissue damage.',
      'content_sw':
          'Kuungua kunahitaji kupozwa mara moja kupunguza uharibifu wa tishu.',
      'steps': [
        'Cool the burn under cool running water for 20 minutes',
        'Remove clothing and jewelry near the burn',
        'Cover with cling film or clean dressing',
        'Do NOT apply ice, butter, or toothpaste',
        'Take painkillers if needed',
        'Seek medical help for serious burns'
      ],
      'steps_sw': [
        'Poza jeraha chini ya maji baridi kwa dakika 20',
        'Ondoa nguo na vito karibu na jeraha',
        'Funika kwa karatasi ya plastiki au bandeji safi',
        'USITUMIE barafu, siagi, au dawa ya meno',
        'Tumia dawa za maumivu ikihitajika',
        'Tafuta msaada wa daktari kwa kuungua kwa uzito'
      ],
    },
    {
      'id': 905,
      'title': 'Fracture First Aid',
      'title_sw': 'Msaada wa Kwanza kwa Kuvunjika',
      'category': 'fractures',
      'content':
          'A fracture is a broken bone that needs immobilization and medical care.',
      'content_sw':
          'Kuvunjika ni mfupa uliovunjika unaohitaji kutosogezwa na matibabu.',
      'steps': [
        'Do not move the injured person',
        'Immobilize the injured area',
        'Apply ice wrapped in cloth to reduce swelling',
        'Use a splint to support the fracture',
        'Control any bleeding with gentle pressure',
        'Call emergency services'
      ],
      'steps_sw': [
        'Usimsogeze mtu aliyeumia',
        'Fanya eneo lililoumia lisitembee',
        'Weka barafu iliyofungwa kitambaa kupunguza uvimbe',
        'Tumia splint kusaidia mfupa uliovunjika',
        'Dhibiti kutoka damu kwa kubonyeza taratibu',
        'Piga simu ya dharura'
      ],
    },
    {
      'id': 906,
      'title': 'Snakebite',
      'title_sw': 'Kuumwa na Nyoka',
      'category': 'snakebite',
      'content':
          'Snakebites can be venomous. Keep calm and seek medical help immediately.',
      'content_sw':
          'Kuumwa na nyoka kunaweza kuwa na sumu. Tulia na tafuta msaada wa daktari haraka.',
      'steps': [
        'Move away from the snake',
        'Keep the person calm and still',
        'Remove jewelry and tight clothing',
        'Keep the bite below heart level',
        'Do NOT suck the venom or apply tourniquet',
        'Get to a hospital with anti-venom as fast as possible'
      ],
      'steps_sw': [
        'Ondoka mbali na nyoka',
        'Mfanye mtu atulie na asitembee',
        'Ondoa vito na nguo zinazobana',
        'Weka jeraha chini ya kiwango cha moyo',
        'USIFANYE kunyonya sumu au kutumia tourniquet',
        'Fika hospitali yenye dawa ya sumu haraka iwezekanavyo'
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _tabCtrl = TabController(length: _categories.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        _loadCategory(_tabCtrl.index);
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _audioPlayer?.dispose();
    for (final c in _videoControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // FEATURE 34: Toggle audio playback
  Future<void> _toggleAudio(FirstAidGuide guide) async {
    if (guide.audioUrl == null) return;

    try {
      if (_playingAudioId == guide.id && _isAudioPlaying) {
        await _audioPlayer?.pause();
        if (!mounted) return;
        setState(() => _isAudioPlaying = false);
        return;
      }

      if (_playingAudioId != guide.id) {
        _audioPlayer?.dispose();
        _audioPlayer = AudioPlayer();
        await _audioPlayer!.setUrl(guide.audioUrl!);
        _playingAudioId = guide.id;
      }

      await _audioPlayer!.play();
      if (!mounted) return;
      setState(() => _isAudioPlaying = true);

      // Listen for completion
      _audioPlayer!.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (!mounted) return;
          setState(() => _isAudioPlaying = false);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSwahili
              ? 'Imeshindwa kucheza sauti: $e'
              : 'Failed to play audio: $e'),
        ),
      );
    }
  }

  // FEATURE 37: Initialize and toggle video
  Future<void> _toggleVideo(FirstAidGuide guide) async {
    if (guide.videoUrl == null) return;

    try {
      if (!_videoControllers.containsKey(guide.id)) {
        final controller =
            VideoPlayerController.networkUrl(Uri.parse(guide.videoUrl!));
        _videoControllers[guide.id] = controller;
        await controller.initialize();
        if (!mounted) return;
        setState(() {});
      }

      final controller = _videoControllers[guide.id]!;
      if (controller.value.isPlaying) {
        await controller.pause();
      } else {
        await controller.play();
      }
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSwahili
              ? 'Imeshindwa kucheza video: $e'
              : 'Failed to play video: $e'),
        ),
      );
    }
  }

  void _loadCategory(int index) {
    final cat = _categories[index].$1;
    _loadWithCategory(cat == 'all' ? null : cat);
  }

  Future<void> _loadWithCategory(String? category) async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.getFirstAidGuides(category: category);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success && result.items.isNotEmpty) {
          _guides = result.items;
        } else {
          // Use offline fallback
          _guides = _offlineGuides
              .where((g) =>
                  category == null || g['category'] == category)
              .map((g) => FirstAidGuide.fromJson(g))
              .toList();
        }
      });
    } catch (e) {
      if (!mounted) return;
      // Offline fallback
      setState(() {
        _isLoading = false;
        _guides = _offlineGuides
            .where((g) =>
                category == null ||
                g['category'] == category)
            .map((g) => FirstAidGuide.fromJson(g))
            .toList();
      });
    }
  }

  Future<void> _load() async {
    await _loadWithCategory(null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
          _isSwahili ? 'Msaada wa Kwanza' : 'First Aid Guide',
          style: const TextStyle(
              color: _kPrimary, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          labelStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              const TextStyle(fontSize: 12),
          indicatorColor: _kPrimary,
          indicatorWeight: 2,
          tabAlignment: TabAlignment.start,
          tabs: _categories.map((cat) {
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat.$4, size: 16),
                  const SizedBox(width: 4),
                  Text(_isSwahili ? cat.$3 : cat.$2),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : _guides.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.medical_services_rounded,
                          size: 48, color: _kSecondary),
                      const SizedBox(height: 12),
                      Text(
                          _isSwahili
                              ? 'Hakuna miongozo'
                              : 'No guides available',
                          style: const TextStyle(
                              color: _kSecondary, fontSize: 14)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _kPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _guides.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final g = _guides[i];
                      final expanded = _expandedId == g.id;
                      final title =
                          _isSwahili ? g.titleSw : g.title;
                      final content =
                          _isSwahili ? g.contentSw : g.content;
                      final steps =
                          _isSwahili ? g.stepsSw : g.steps;

                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            ListTile(
                              onTap: () => setState(() {
                                _expandedId =
                                    expanded ? null : g.id;
                              }),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _kRed.withValues(
                                      alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                    Icons
                                        .medical_services_rounded,
                                    color: _kRed,
                                    size: 20),
                              ),
                              title: Text(title,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight.w500,
                                      color: _kPrimary),
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis),
                              subtitle: Text(g.category,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: _kSecondary)),
                              trailing: Icon(
                                expanded
                                    ? Icons
                                        .keyboard_arrow_up_rounded
                                    : Icons
                                        .keyboard_arrow_down_rounded,
                                color: _kSecondary,
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 4),
                            ),
                            if (expanded) ...[
                              const Divider(height: 1),
                              Padding(
                                padding:
                                    const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // FIX 5: Show illustration image if available
                                    if (g.imageUrl != null) ...[
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        child: Image.network(
                                          g.imageUrl!,
                                          width: double.infinity,
                                          height: 180,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, _, _) =>
                                                  Container(
                                            height: 100,
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                  0xFFF0F0F0),
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                          10),
                                            ),
                                            child: Center(
                                              child: Text(
                                                _isSwahili
                                                    ? 'Picha haipatikani'
                                                    : 'Image unavailable',
                                                style:
                                                    const TextStyle(
                                                        fontSize:
                                                            12,
                                                        color:
                                                            _kSecondary),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    if (content.isNotEmpty)
                                      Text(content,
                                          style:
                                              const TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      _kPrimary,
                                                  height: 1.5)),
                                    if (steps.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                          _isSwahili
                                              ? 'Hatua:'
                                              : 'Steps:',
                                          style:
                                              const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight
                                                          .w600,
                                                  color:
                                                      _kPrimary)),
                                      const SizedBox(height: 6),
                                      ...steps
                                          .asMap()
                                          .entries
                                          .map((e) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets
                                                  .only(
                                                  bottom: 6),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            children: [
                                              Container(
                                                width: 22,
                                                height: 22,
                                                decoration:
                                                    const BoxDecoration(
                                                  shape:
                                                      BoxShape
                                                          .circle,
                                                  color:
                                                      _kPrimary,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                      '${e.key + 1}',
                                                      style: const TextStyle(
                                                          fontSize:
                                                              11,
                                                          color: Colors
                                                              .white,
                                                          fontWeight:
                                                              FontWeight.w600)),
                                                ),
                                              ),
                                              const SizedBox(
                                                  width: 10),
                                              Expanded(
                                                child: Text(
                                                    e.value,
                                                    style: const TextStyle(
                                                        fontSize:
                                                            13,
                                                        color:
                                                            _kPrimary,
                                                        height:
                                                            1.4)),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],

                                    // FEATURE 34: Audio play button
                                    if (g.audioUrl != null) ...[
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _toggleAudio(g),
                                          icon: Icon(
                                            _playingAudioId ==
                                                        g.id &&
                                                    _isAudioPlaying
                                                ? Icons
                                                    .pause_rounded
                                                : Icons
                                                    .play_arrow_rounded,
                                            size: 20,
                                          ),
                                          label: Text(
                                            _isSwahili
                                                ? (_playingAudioId ==
                                                            g.id &&
                                                        _isAudioPlaying
                                                    ? 'Simamisha'
                                                    : 'Sikiliza')
                                                : (_playingAudioId ==
                                                            g.id &&
                                                        _isAudioPlaying
                                                    ? 'Pause'
                                                    : 'Listen'),
                                            style:
                                                const TextStyle(
                                                    fontSize: 13),
                                          ),
                                          style: OutlinedButton
                                              .styleFrom(
                                            foregroundColor:
                                                _kPrimary,
                                            side: const BorderSide(
                                                color: Color(
                                                    0xFFE0E0E0)),
                                            shape:
                                                RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                          10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],

                                    // FEATURE 37: Video player
                                    if (g.videoUrl != null) ...[
                                      const SizedBox(height: 12),
                                      if (_videoControllers
                                              .containsKey(
                                                  g.id) &&
                                          _videoControllers[g.id]!
                                              .value
                                              .isInitialized) ...[
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(10),
                                          child: AspectRatio(
                                            aspectRatio:
                                                _videoControllers[
                                                        g.id]!
                                                    .value
                                                    .aspectRatio,
                                            child: VideoPlayer(
                                                _videoControllers[
                                                    g.id]!),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 48,
                                          child:
                                              OutlinedButton.icon(
                                            onPressed: () =>
                                                _toggleVideo(g),
                                            icon: Icon(
                                              _videoControllers[
                                                          g.id]!
                                                      .value
                                                      .isPlaying
                                                  ? Icons
                                                      .pause_rounded
                                                  : Icons
                                                      .play_arrow_rounded,
                                              size: 20,
                                            ),
                                            label: Text(
                                              _videoControllers[
                                                          g.id]!
                                                      .value
                                                      .isPlaying
                                                  ? (_isSwahili
                                                      ? 'Simamisha Video'
                                                      : 'Pause Video')
                                                  : (_isSwahili
                                                      ? 'Endelea Video'
                                                      : 'Play Video'),
                                              style:
                                                  const TextStyle(
                                                      fontSize:
                                                          13),
                                            ),
                                            style: OutlinedButton
                                                .styleFrom(
                                              foregroundColor:
                                                  _kPrimary,
                                              side:
                                                  const BorderSide(
                                                      color: Color(
                                                          0xFFE0E0E0)),
                                              shape:
                                                  RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                            10),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ] else
                                        SizedBox(
                                          width: double.infinity,
                                          height: 48,
                                          child:
                                              OutlinedButton.icon(
                                            onPressed: () =>
                                                _toggleVideo(g),
                                            icon: const Icon(
                                                Icons
                                                    .videocam_rounded,
                                                size: 20),
                                            label: Text(
                                              _isSwahili
                                                  ? 'Tazama Video'
                                                  : 'Watch Video',
                                              style:
                                                  const TextStyle(
                                                      fontSize:
                                                          13),
                                            ),
                                            style: OutlinedButton
                                                .styleFrom(
                                              foregroundColor:
                                                  _kPrimary,
                                              side:
                                                  const BorderSide(
                                                      color: Color(
                                                          0xFFE0E0E0)),
                                              shape:
                                                  RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                            10),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
