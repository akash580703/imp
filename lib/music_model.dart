// To parse this JSON data, do
//
//     final music = musicFromJson(jsonString);

import 'package:meta/meta.dart';
import 'dart:convert';

Music musicFromJson(var str) => Music.fromJson(str);

String musicToJson(Music data) => json.encode(data.toJson());

class Music {
    Music({
        required this.status,
        required this.message,
        required this.musicGenre,
    });

    String status;
    String message;
    List<MusicGenre> musicGenre;

    factory Music.fromJson(Map<String, dynamic> json) => Music(
        status: json["status"]??"null",
        message: json["message"]??"null",
        musicGenre: List<MusicGenre>.from(json["music_genre"].map((x) { 
  
           return MusicGenre.fromJson(x);

         })),
    );

    Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "music_genre": List<dynamic>.from(musicGenre.map((x) => x.toJson())),
    };
}

class MusicGenre {
    MusicGenre({
        required this.genre,
        required this.genreAlbums,
    });

    String genre;
    List<GenreAlbum> genreAlbums;

    factory MusicGenre.fromJson(Map<String, dynamic> json) => MusicGenre(
        genre: json["genre"]??"null",
        genreAlbums: List<GenreAlbum>.from(json["genre_albums"].map(
          (x) =>
           GenreAlbum.fromJson(x)))??[],
    );

    Map<String, dynamic> toJson() => {
        "genre": genre,
        "genre_albums": List<dynamic>.from(genreAlbums.map((x) => x.toJson())),
    };
}

class GenreAlbum {
    GenreAlbum({
        required this.id,
        required this.title,
        required this.subtitle,
        required this.headerDesc,
        required this.type,
        required this.permaUrl,
        required this.image,
        required this.language,
        required this.year,
        required this.playCount,
        required this.explicitContent,
        required this.listCount,
        required this.listType,
        required this.list,
        required this.moreInfo,
        required this.modules,
    });

    String id;
    String title;
    String subtitle;
    String headerDesc;
    String type;
    String permaUrl;
    String image;
    String language;
    String year;
    String playCount;
    String explicitContent;
    String listCount;
    String listType;
    String list;
    MoreInfo moreInfo;
    dynamic modules;

    factory GenreAlbum.fromJson(Map<String, dynamic> json) => GenreAlbum(
        id: json["id"]??"null",
        title: json["title"]??"null",
        subtitle: json["subtitle"]??"null",
        headerDesc: json["header_desc"]??"null",
        type: json["type"]??"null",
        permaUrl: json["perma_url"]??"null",
        image: json["image"]??"null",
        language: json["language"]??"null",
        year: json["year"]??"null",
        playCount: json["play_count"]??"null",
        explicitContent: json["explicit_content"]??"null",
        listCount: json["list_count"]??"null",
        listType: json["list_type"]??"null",
        list: json["list"]??"null",
        moreInfo: MoreInfo.fromJson(json["more_info"]),
        modules: json["modules"]??"null",
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "subtitle": subtitle,
        "header_desc": headerDesc,
        "type": type,
        "perma_url": permaUrl,
        "image": image,
        "language": language,
        "year": year,
        "play_count": playCount,
        "explicit_content": explicitContent,
        "list_count": listCount,
        "list_type": listType,
        "list": list,
        "more_info": moreInfo.toJson(),
        "modules": modules,
    };
}

class MoreInfo {
    MoreInfo({
        required this.isWeekly,
        required this.firstname,
        required this.songCount,
        required this.followerCount,
        required this.fanCount,
    });

    String isWeekly;
    String firstname;
    String songCount;
    String followerCount;
    String fanCount;

    factory MoreInfo.fromJson(Map<String, dynamic> json) => MoreInfo(
        isWeekly: json["isWeekly"]??"null",
        firstname: json["firstname"]??"null",
        songCount: json["song_count"]??"null",
        followerCount: json["follower_count"]??"null",
        fanCount: json["fan_count"]??"null",
    );

    Map<String, dynamic> toJson() => {
        "isWeekly": isWeekly,
        "firstname": firstname,
        "song_count": songCount,
        "follower_count": followerCount,
        "fan_count": fanCount,
    };
}
