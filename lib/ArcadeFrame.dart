// TODO: Clean up sources. I just copy pasted.
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:async/async.dart';
import 'dart:convert';
import 'package:flutter/scheduler.dart';
import 'package:auto_orientation/auto_orientation.dart';

import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:http/http.dart' as http;
import "Game.dart";
import "GameScreen.dart";
import "Constants.dart";
import "Database.dart";

import 'dart:developer';

class ArcadeFrame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        home: HomeScreen(),
        theme: ThemeData(fontFamily: 'Helvetica') //default font for entire app
        );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  State createState() => new HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final searchController = TextEditingController();
  final DBProvider db = DBProvider.db;
  String gamesLabel = "Popular Games";
  List<Game> savedGames = [];

  @override
  void initState() {
    db.initDB();
    // TODO: Once we set up a favourite button
    // Something like getFavouriteGames()
    _loadGames(API_SOME);
    searchController.addListener(_searchGames);
  }

  _loadGames(String url) async {
    getGames(url).then((result) {
      setState(() {
        savedGames = result;
      });
    });
  }

  // Redisearch also provides something called suggestion completion. Something
  // we could do, but our 0.5GB RAM VM, is struggling as is.
  _searchGames() async {
    if (searchController.text == "") {
      _loadGames(API_SOME);
      return;
    }
    _loadGames("${API_SEARCH}=${searchController.text}");
  }

  // TODO: Also update api that game was played.
  // Potential race condition, becasue PageBuilder expects the game to be set.
  // but I think to get to that point is pretty slow, so we should be good.
  Future saveGame(Game game) async {
    game.plays += 1;
    if (game.saved) {
      return db.updateGame(game);
    }
    return db.newGame(game);
  }

  Future getGames(String url) async {
    return http.get(Uri.encodeFull(url),
        headers: {"Accept": "application/json"}).then((response) {
      var body = json.decode(response.body);
      List<Game> games =
          body["results"].map<Game>((json) => Game.fromMap(json)).toList();
      return db.backfillGames(games);
    });
  }

  Future getFavouriteGames() async {
    // TODO: Extract favorite games for display
  }

  @override
  Widget build(BuildContext context) {
    final Orientation orientation = MediaQuery.of(context).orientation;
    final bool isLandscape = orientation == Orientation.landscape;

    if (isLandscape) {
      return Scaffold(body: Container(color: Color(0xFF73000a)));
    }

    @override
    void dispose() {
      // Clean up the controller when the widget is removed from the
      // widget tree.
      searchController.dispose();
      super.dispose();
    }

    // TODO: We can probably make this prettier :)
    // Good job so far though.
    return Scaffold(
        body: Container(
            color: Color(0xFF73000a),
            child: Padding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.width * 0.1),
                child: Column(children: [
                  Padding(
                      padding: EdgeInsets.only(left: 20),
                      child: Row(children: [
                        Column(children: [
                          Row(children: <Widget>[
                            new Text('Arcade ',
                                style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.075,
                                    fontFamily: "arcadeclassic",
                                    color: Colors.white)),
                            new Text('Frame',
                                style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width * 0.1,
                                    fontFamily: "arcadeclassic",
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold))
                          ]),
                        ]),
                        Column(children: [
                          Padding(
                              padding: EdgeInsets.only(bottom: 0),
                              child: IconButton(
                                iconSize:
                                    MediaQuery.of(context).size.width * 0.1,
                                icon:
                                    new Image.asset("assets/icons/gamepad.png"),
                              ))
                        ])
                      ])),
                  Padding(padding: EdgeInsets.symmetric(vertical: 10)),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: TextField(
                          style: TextStyle(color: Colors.white),
                          decoration: new InputDecoration(
                              enabledBorder: new OutlineInputBorder(
                                  borderSide: new BorderSide(
                                      color: Colors.white, width: 2.0)),
                              focusedBorder: new OutlineInputBorder(
                                  borderSide: new BorderSide(
                                      color: Colors.white, width: 2.0)),
                              hintText: 'Keywords in the title',
                              labelText: 'Search for a game',
                              prefixIcon: const Icon(
                                Icons.code,
                                color: Colors.white,
                              ),
                              labelStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                              hintStyle: const TextStyle(color: Colors.white)),
                          controller: searchController)),
                  Padding(padding: EdgeInsets.symmetric(vertical: 10)),
                  new Text(gamesLabel,
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.05,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  new ListView.builder(
                      padding: EdgeInsets.all(0.0),
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: savedGames.length,
                      itemBuilder: (BuildContext ctxt, int index) {
                        return new RaisedButton(
                          color: Colors.white,
                          child: Text(savedGames[index].name),
                          onPressed: () {
                            saveGame(savedGames[index]);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => GameScreen(
                                          game: savedGames[index],
                                        )));
                          },
                        );
                      }),
                ]))));
  }
}
