import 'package:flutter/material.dart';

class MusicObject {
  String title;
  String id;
  String albums;
  String album_id;
  String imageUrl;
  Color bgc;
  String mp3;

  MusicObject({
    required this.id,
    required this.title,
    required this.albums,
    required this.album_id,
    required this.imageUrl,
    required this.mp3,
    required this.bgc
  });
}


