import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Colors.dart';

class IgniteDialog extends StatelessWidget {
  const IgniteDialog({Key key, @required this.title, @required this.page})
      : super(key: key);

  final String title;
  final String page;

  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: Text(title),
        trailing: Icon(Icons.arrow_forward),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute<Null>(
                builder: (BuildContext context) {
                  return new Scaffold(
                    appBar: new AppBar(
                      backgroundColor: BAR_COLOR,
                      title: Text(title),
                    ),
                    body: SafeArea(
                      minimum: EdgeInsets.all(10),
                      child: FutureBuilder(
                          future: rootBundle.loadString(page),
                          builder: (BuildContext context,
                              AsyncSnapshot<String> snapshot) {
                            if (snapshot.hasData) {
                              return Markdown(
                                  selectable: false,
                                  data: snapshot.data,
                                  onTapLink: (String url) async {
                                    debugPrint(url);
                                    if (await canLaunch(url)) {
                                      await launch(
                                        url,
                                        forceSafariVC: false,
                                        forceWebView: false,
                                      );
                                    }
                                  });
                            }

                            return Markdown(data: "## Loading...");
                          }),
                    ),
                  );
                },
                fullscreenDialog: true,
              ));
        });
  }
}
