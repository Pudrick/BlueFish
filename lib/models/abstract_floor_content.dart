import 'package:bluefish/models/author.dart';

abstract class FloorContent {
  late Author author;

  late String postTimeReadable; // can be infer from postTime
  late DateTime postTime;
  late String postLocation;

  late String contentHTML;

  late String client;
}
