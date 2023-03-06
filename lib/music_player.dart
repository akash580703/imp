import 'dart:convert';
import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:imp_app/music_model.dart';
import 'package:imp_app/music_object_model.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:palette_generator/palette_generator.dart';

class PlayerButtons extends StatefulWidget {
  PlayerButtons() : super();

  @override
  State<PlayerButtons> createState() => _PlayerButtonsState();
}

class _PlayerButtonsState extends State<PlayerButtons> {
  late AudioPlayer _audioPlayer;
  bool flag = true;
  Color bg = Colors.white;
  late List<MusicGenre> musicGenre;
  late bool showPlayer;
  late bool showGenre;

  late bool showSongList;

  late List<MusicObject> filterMusicObject;
  late String genreName;


  List<MusicObject> listMusicObject = [];

  Future<Color> getImagePalette(String link) async {
    final PaletteGenerator generator = await PaletteGenerator.fromImageProvider(
      NetworkImage(link),
      timeout: const Duration(seconds: 60),
    );

    print("paletteGenerator");


    return generator.lightVibrantColor!.color;
  }

  late ConcatenatingAudioSource playlist;

  Future getAllSongs() async {
    playlist = ConcatenatingAudioSource(

      useLazyPreparation: true,
      shuffleOrder: DefaultShuffleOrder(),
      children: [],
    );
    String url = "https://thecxoleague.com/imp/app-genre-albums-list";
    try {
      http.Response res = await http.post(Uri.parse(url));
      debugPrint(res.toString());

      if (res.statusCode == 200) {
        var body = jsonDecode(res.body);
        if (body["status"] == "success") {
          Music music = musicFromJson(body);

          setState(() {
            musicGenre = music.musicGenre
                .where((element) => element.genreAlbums.isNotEmpty)
                .toList();
          });

          music.musicGenre.forEach((element) {
            for (var genere in element.genreAlbums) {
              if (element.genreAlbums.isNotEmpty) {
                getSongsUrl(genere.id);
              } else {
                print("empty...");
              }
            }
          });
        }
      } else {
     
      }

      return true;
    } catch (e) {
  
      throw Exception(e);
    }
  }

  getSongsUrl(String id) async {
    var headers = {
      'Cookie': 'ci_session=6ea9ca1870b34f20d5459e77b62f1bac58593d2c'
    };
    var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://thecxoleague.com/imp/app-album-songs-list?album_id=4'));
    request.fields.addAll({'album_id': id});

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var streamedResponse = await http.Response.fromStream(response);
      var parsed = jsonDecode(streamedResponse.body);

      for (var songs in parsed["album_songs"]) {
        MusicObject musicObject = MusicObject(
            id: songs["id"],
            title: songs["title"],
            albums: songs["album"],
            imageUrl: songs["image"],
            mp3: songs["url"],
            album_id: songs["album_id"],
            bgc: await getImagePalette(songs["image"]));

        listMusicObject.add(musicObject);

        setState(() {
          playlist.add(
              AudioSource.uri(Uri.parse(musicObject.mp3), tag: musicObject));
          if (playlist.children.isNotEmpty) {
            flag = true;
          }
        });
      }
    } else {
      print(response.reasonPhrase);
    }
  }

  @override
  void initState() {
    _audioPlayer = AudioPlayer();
    getAllSongs().then((value) => _audioPlayer.setAudioSource(playlist,
        initialIndex: 0, initialPosition: Duration.zero));
    showPlayer = false;
    showGenre = true;

    showSongList = false;
    filterMusicObject = [];
    genreName = "";

    super.initState();
  }

  @override
  void dispose() {
    // Release decoders and buffers back to the operating system making them
    // available for other apps to use.
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // Release the player's resources when not in use. We use "stop" so that
      // if the app resumes later, it will still remember what position to
      // resume from.||
      _audioPlayer.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    Stream<Duration> start = _audioPlayer.positionStream;
    Stream<Duration> buffered = _audioPlayer.bufferedPositionStream;
    Stream<Duration?> total = _audioPlayer.durationStream;

    double w = MediaQuery.of(context).size.width;

    double h = MediaQuery.of(context).size.height;
    print(playlist.children.length);

    return SafeArea(
      child: Scaffold(
        floatingActionButton: !showPlayer
            ? FloatingActionButton(
                backgroundColor: Colors.green,
                foregroundColor: Colors.black,
                mini: true,
                onPressed: () {
                  setState(() {
                    showPlayer = true;
                  });
                },
                child: Icon(Icons.play_arrow),
              )
            : null,
        body: StreamBuilder<SequenceState?>(
            stream: _audioPlayer.sequenceStateStream,
            builder: (context, obj) {
              if (obj.data != null && obj.data!.currentSource != null) {
                return Stack(children: [
                  Visibility(
                    visible: !showPlayer,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                  // SHOW/HIDE SONG LIST WIDGET

                        showSongList
                            ? songListWidget(
                                filterMusicObject, genreName, obj.data!)
                  // SHOW/HIDE GENRE GRID WIDGET

                            : genreListWidget(
                                context, musicGenre, listMusicObject),
                      ],
                    ),
                  ),


                  // MAIN MUSIC PLAYER WIDGET
                  Visibility(
                    visible: showPlayer,
                    child: Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: Container(
                          decoration: BoxDecoration(
                            // borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              colors: [
                                obj.data!.currentSource!.tag.bgc,
                                Color.fromARGB(170, 0, 0, 0)
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 30,
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        showSongList = false;
                                        showPlayer = false;
                                      });
                                    },
                                  ),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 5,
                                  ),
                                  Text(
                                    "IMP",
                                    textAlign: TextAlign.left,
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 25,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    "  by Akash sahu",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.lato(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  Expanded(child: SizedBox()),
                                  IconButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: true,
                                          builder: (_) => StatefulBuilder(
                                            builder: (context, setState) =>
                                                AlertDialog(
                                              backgroundColor: Color.fromARGB(
                                                  247, 255, 255, 255),

                                              actionsAlignment:
                                                  MainAxisAlignment.center,

                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(12.0),
                                                ),
                                              ),
                                              content: Builder(
                                                builder: (context) {
                                             
                                                  return SizedBox(
                                                    width: 100,
                                                    child: ListView.separated(
                                                        shrinkWrap: true,
                                                        separatorBuilder:
                                                            (context, index) {
                                                          return Divider(
                                                            color: Colors.white,
                                                            height: 10,
                                                            thickness: 0,
                                                          );
                                                        },
                                                        itemCount: _audioPlayer
                                                            .sequenceState!
                                                            .effectiveSequence
                                                            .length,
                                                        itemBuilder:
                                                            (context, i) {
                                                          return GestureDetector(
                                                            onTap: () {
                                                              Navigator.pop(
                                                                  context);

                                                              _audioPlayer
                                                                  .setAudioSource(
                                                                      playlist,
                                                                      initialIndex:
                                                                          i,
                                                                      initialPosition:
                                                                          Duration
                                                                              .zero)
                                                                  .then(
                                                                      (value) {});
                                                            },
                                                            child: ListTile(
                                                              tileColor: obj
                                                                          .data!
                                                                          .currentSource ==
                                                                      _audioPlayer
                                                                              .sequenceState!
                                                                              .effectiveSequence[
                                                                          i]
                                                                  ? obj
                                                                      .data!
                                                                      .currentSource!
                                                                      .tag
                                                                      .bgc
                                                                  : Color
                                                                      .fromARGB(
                                                                          255,
                                                                          231,
                                                                          239,
                                                                          237),

                                                              title: Text(_audioPlayer
                                                                  .sequenceState!
                                                                  .effectiveSequence[
                                                                      i]
                                                                  .tag
                                                                  .title),
                                   
                                                            ),
                                                          );
                                                        }),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      icon: Icon(
                                        Icons.menu,
                                        color: Colors.white,
                                      ))
                                ],
                              ),
                              Expanded(child: SizedBox()),
                              StreamBuilder<SequenceState?>(
                                stream: _audioPlayer.sequenceStateStream,
                                builder: (_, seq) {
                                  //  print(seq.data!.currentIndex.toString());

                                  return Image.network(
                                    seq.data!.currentSource!.tag.imageUrl,
                                    width: w / 1.2,
                                    height: h / 2.7,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                              Expanded(child: SizedBox()),
                              StreamBuilder<SequenceState?>(
                                stream: _audioPlayer.sequenceStateStream,
                                builder: (_, seq) {
                                  //  print(seq.data!.currentIndex.toString());

                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        seq.data!.currentSource!.tag.title,
                                        style: GoogleFonts.lato(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900),
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                        seq.data!.currentSource!.tag.albums,
                                        style: GoogleFonts.lato(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w400),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              SizedBox(
                                height: 30,
                              ),
                              StreamBuilder<Duration>(
                                  stream: start,
                                  builder: (context,
                                      AsyncSnapshot<Duration> start_snapshot) {
                                    return StreamBuilder<Duration>(
                                        stream: buffered,
                                        builder: (context,
                                            AsyncSnapshot<Duration> snapshot) {
                                          return StreamBuilder<Duration?>(
                                              stream: total,
                                              builder: (context,
                                                  AsyncSnapshot<Duration?>
                                                      total_snapshot) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 37.0,
                                                          right: 37.0),
                                                  child: ProgressBar(
                                                    onSeek: (value) {
                                                      _audioPlayer.seek(value);
                                                    },
                                                    baseBarColor: Colors.white,
                                                    thumbColor: Colors.white,
                                                    bufferedBarColor: obj.data!
                                                        .currentSource!.tag.bgc,
                                                    progress:
                                                        start_snapshot.data ??
                                                            Duration(),
                                                    buffered: snapshot.data,
                                                    timeLabelTextStyle:
                                                        TextStyle(
                                                            color:
                                                                Colors.white),
                                                    total:
                                                        total_snapshot.data ??
                                                            Duration(),
                                                  ),
                                                );
                                              });
                                        });
                                  }),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  StreamBuilder<bool>(
                                    stream:
                                        _audioPlayer.shuffleModeEnabledStream,
                                    builder: (context, snapshot) {
                                      return _shuffleButton(
                                          context, snapshot.data ?? false);
                                    },
                                  ),
                                  StreamBuilder<SequenceState?>(
                                    stream: _audioPlayer.sequenceStateStream,
                                    builder: (_, __) {
                                      return _previousButton();
                                    },
                                  ),
                                  StreamBuilder<PlayerState>(
                                    stream: _audioPlayer.playerStateStream,
                                    builder: (_, snapshot) {
                                      final playerState = snapshot.data;
                                      return _playPauseButton(playerState!);
                                    },
                                  ),
                                  StreamBuilder<SequenceState?>(
                                    stream: _audioPlayer.sequenceStateStream,
                                    builder: (_, seq) {
                                      //  print(seq.data!.currentIndex.toString());
                                      return _nextButton();
                                    },
                                  ),
                                  StreamBuilder<LoopMode>(
                                    stream: _audioPlayer.loopModeStream,
                                    builder: (context, snapshot) {
                                      return _repeatButton(context,
                                          snapshot.data ?? LoopMode.off);
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 30,
                              ),
                            ],
                          ),
                        )),
                  ),
                ]);
              } else {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(child: CircularProgressIndicator()),
                  ],
                );
              }
            }),
      ),
    );
  }

// SONG_LIST WIDGET
  Widget songListWidget(
      List<MusicObject> musicObject, String genreName, SequenceState obj) {
    return Container(
      height: MediaQuery.of(context).size.height - 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            title: Text(genreName),
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  showSongList = false;
                });
              },
            ),
          ),
          Expanded(
            child: Container(
              child:
                  SingleChildScrollView(child: _buildItems(musicObject, obj)),
            ),
          ),
        ],
      ),
    );
  }

// PLAY OPTION WIDGET

  Widget playOption(
      MusicObject musicObject, BuildContext context, SequenceState obj) {
                                                             

    int index = _audioPlayer.sequenceState!.effectiveSequence
            .indexOf(obj.currentSource!) +
        1;

    return SizedBox(
      width: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [


// PLAY NOW WIDGET

          GestureDetector(
              onTap: () async {
                print(playlist.children.length);

                playlist
                    .insert(
                        0,
                        AudioSource.uri(Uri.parse(musicObject.mp3),
                            tag: musicObject))
                    .then((value) async {
                  print(playlist.children.length);

                  await _audioPlayer
                      .setAudioSource(playlist,
                          initialIndex: 0, initialPosition: Duration.zero)
                      .then((value) {});
                });

                setState(() {
                  showSongList = false;
                  showPlayer = true;
                });

                Navigator.pop(context);
                _audioPlayer.play();
              },
              child: ListTile(
                title: Text("Play Now"),
              )),




// PLAY NEXT WIDGET

          GestureDetector(
            onTap: () async {
              print(playlist.children.length);

              setState(() {
                // showSongList = false;
                // showPlayer = true;

                if (index ==
                    _audioPlayer.sequenceState!.effectiveSequence.length) {
                  playlist
                      .add(
                    AudioSource.uri(Uri.parse(musicObject.mp3),
                        tag: musicObject),
                  )
                      .then((value) {
                    print(playlist.children.length);

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Added as next song"),
                    ));
                  });
                } else {
                  playlist
                      .insert(
                          index,
                          AudioSource.uri(Uri.parse(musicObject.mp3),
                              tag: musicObject))
                      .then((value) {
                    print(playlist.children.length);

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Added as next song"),
                    ));
                  });
                }
              });

              Navigator.pop(context);
            },
            child: ListTile(
              title: Text("Play Next"),
            ),
          ),



// ADD TO QUEUE WIDGET

          GestureDetector(
            onTap: () {
              playlist
                  .add(AudioSource.uri(
                      Uri.parse(
                        musicObject.mp3,
                      ),
                      tag: musicObject))
                  .then((value) {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Song added to queue"),
                ));
              });
            },
            child: ListTile(
              title: Text("Add to Queue"),
            ),
          ),
        ],
      ),
    );
  }




// SONG LIST ITEM WIDGET
  Widget _buildItems(List<MusicObject> musicObject, SequenceState obj) {
    return ListView.separated(
        shrinkWrap: true,
        separatorBuilder: (context, index) {
          return Divider(
            color: Colors.white,
            height: 10,
            thickness: 0,
          );
        },
        itemCount: musicObject.length,
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (_) => AlertDialog(
                  backgroundColor: Color.fromARGB(247, 255, 255, 255),

                  actionsAlignment: MainAxisAlignment.center,

               
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(12.0),
                    ),
                  ),
                  content: Builder(
                    builder: (context) {
               
                      return SizedBox(
                        width: 100,
                        child: playOption(musicObject[i], context, obj),
                      );
                    },
                  ),
                ),
              );
            },
            child: ListTile(
              tileColor: Color.fromARGB(255, 231, 239, 237),

              title: Text(musicObject[i].title),
              // trailing: IconButton(icon: Icon(Icons.more_vert),onPressed: (){

              // },),

              // Text("Regulaization Pending",style: Styles.poppinsRegular.copyWith(color: Strings.ColorRed,fontSize: 12),),

              // title: Obx(
              //   () => Text(
              //     // myAttendanceCtrl.stateMyAttendanceModel.last.data[i]
              //     //     .loginregularised
              //     //     .toString(),
              //     myAttendanceCtrl.stateMyAttendanceModel.last.data[i]
              //         .loginregularised
              //         .toString(),
              //     style: Styles.poppinsRegular
              //         .copyWith(color: Strings.ColorBlue, fontSize: 12),
              //     textAlign: TextAlign.center,
              //   ),
              // ),

              // Icon(Icons.check_circle,color: Strings.ColorBlue,size:width/10),
            ),
          );
        });
  }



// GENRE GRID WIDGET
  Container genreListWidget(BuildContext context, List<MusicGenre> musicGenre,
      List<MusicObject> musicObject) {
    return Container(
      height: MediaQuery.of(context).size.height - 60,
      width: MediaQuery.of(context).size.width,
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Text(
              "Genre",
              style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900),
            ),
          ),

          GridView.builder(
              shrinkWrap: true,
              // ignore: prefer_const_constructors
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                crossAxisCount: 2,
                childAspectRatio: 2.0,
              ),
              itemCount: musicGenre.length,
              itemBuilder: (x, i) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      filterMusicObject = musicObject
                          .where((element) =>
                              element.album_id ==
                              musicGenre[i].genreAlbums[0].id)
                          .toList();
                      genreName = musicGenre[i].genre;
                      showSongList = true;
                    });


                  },
                  child: Container(
                    height: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(

                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        Text(musicGenre[i].genre),
                      ],
                    ),
                  ),
                );
              }),
          // Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _playPauseButton(PlayerState playerState) {
    final processingState = playerState?.processingState;
    if (processingState == ProcessingState.loading ||
        processingState == ProcessingState.buffering) {
      return Container(
        margin: EdgeInsets.all(8.0),
        width: 64.0,
        height: 64.0,
        child: CircularProgressIndicator(),
      );
    } else if (_audioPlayer.playing != true) {
      print(_audioPlayer.sequenceState!.currentSource!.tag);
      return IconButton(
        icon: Icon(Icons.play_arrow),
        color: Colors.white,
        iconSize: 64.0,
        onPressed: _audioPlayer.play,
      );
    } else if (processingState != ProcessingState.completed) {
      return IconButton(
        icon: Icon(Icons.pause),
        color: Colors.white,
        iconSize: 64.0,
        onPressed: _audioPlayer.pause,
      );
    } else {
      return IconButton(
        icon: Icon(Icons.replay),
        color: Colors.white,
        iconSize: 64.0,
        onPressed: () => _audioPlayer.seek(Duration.zero,
            index: _audioPlayer.effectiveIndices!.first),
      );
    }
  }

  Widget _shuffleButton(BuildContext context, bool isEnabled) {
    return IconButton(
      icon: isEnabled
          ? Icon(Icons.shuffle, color: Theme.of(context).accentColor)
          : Icon(
              Icons.shuffle,
              color: Colors.white,
            ),
      onPressed: () async {
        final enable = !isEnabled;
        if (enable) {
          await _audioPlayer.shuffle();
        }
        await _audioPlayer.setShuffleModeEnabled(enable);
      },
    );
  }

  Widget _previousButton() {
    return IconButton(
        icon: Icon(Icons.skip_previous),
        color: Colors.white,
        onPressed: () {
          if (_audioPlayer.hasPrevious) {
            _audioPlayer.seekToPrevious();

            if (_audioPlayer.playing != true) {
              _audioPlayer.play();
            }
          }
        });
  }

  Widget _nextButton() {
    return IconButton(
        icon: Icon(Icons.skip_next),
        color: Colors.white,
        onPressed: () {
          if (_audioPlayer.hasNext) {
            _audioPlayer.seekToNext();

            if (_audioPlayer.playing != true) {
              _audioPlayer.play();
            }
          }
        });
  }

  Widget _repeatButton(BuildContext context, LoopMode loopMode) {
    final icons = [
      Icon(
        Icons.repeat,
        color: Colors.white,
      ),
      Icon(Icons.repeat, color: Theme.of(context).accentColor),
      Icon(Icons.repeat_one, color: Theme.of(context).accentColor),
    ];
    const cycleModes = [
      LoopMode.off,
      LoopMode.all,
      LoopMode.one,
    ];
    final index = cycleModes.indexOf(loopMode);
    return IconButton(
      icon: icons[index],
      onPressed: () {
        _audioPlayer.setLoopMode(
            cycleModes[(cycleModes.indexOf(loopMode) + 1) % cycleModes.length]);
      },
    );
  }
}
