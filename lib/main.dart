import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:share/share.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class JournalStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/journal.json');
  }

  Future<File> get localFile async {
    final path = await _localPath;
    return File('$path/journal.json');
  }

  Future<String> readJournal() async {
    try {
      final file = await _localFile;

      // Read the file
      String contents = await file.readAsString();

      return contents;
    } catch (e) {
      // If encountering an error, return 0
      return '';
    }
  }

  Future<File> writeJournal(String data) async {
    final file = await _localFile;

    // Write the file
    return file.writeAsString(data);
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Газета VEGETARIAN',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(
        title: 'Газета VEGETARIAN',
        contentURL: 'https://raw.githubusercontent.com/ymakei/vegetarian_journal/master/assets/journal.json',
        storage: JournalStorage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage(
    {Key key,
      this.title,
      this.contentURL,
      @required this.storage,
  }) : super(key: key);

  final String title;
  final String contentURL;
  final JournalStorage storage;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  var contentFile;
  String _journalPath = 'assets/journal.json';

  @override
  void initState() {
    super.initState();

    widget.storage.localFile.then(
      (File file) {
        // setState(() {
        //     _journalPath = file.path;
        // });
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
       title: Text(widget.title),
      ),
      body: Container(
        child: FutureBuilder(
          future: DefaultAssetBundle
            .of(context)
            .loadString(_journalPath),
          builder: (context, snapshot) {
            // Read json-data
            var listData = json.decode(snapshot.data.toString());

            return RefreshIndicator(
              onRefresh: _refreshListView ,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: (BuildContext context, int index) {
                  return JournalCard(
                    titleText: listData[index]['title'],
                    pdfURL: listData[index]['pdfURL'],
                    imgURL: listData[index]['imgURL'],
                    isAvailable: listData[index]['pdfURL'].toString().isNotEmpty,
                  );
                },
                itemCount: listData == null ? 0 : listData.length,
              )
            );
          },
        ),
      ),
    );
  }

  Future<Null> _refreshListView() async {
    final response = await http.get(widget.contentURL);

    if (response.statusCode == 200) {
      // If the call to the server was successful, parse the JSON.
      widget.storage.writeJournal(response.body).then(
        (File file) {
          setState(() {
              _journalPath = file.path;
          });
        }
      );
      /*
      widget.storage.localFile.then(
        (File file) {
      });
      */
    }
  }

}

class JournalCard extends StatefulWidget {
  const JournalCard({Key key,
    this.titleText,
    this.pdfURL,
    this.imgURL,
    this.isAvailable,
  }) : super(key : key);

  final String titleText;
  final String imgURL;
  final String pdfURL;
  final bool isAvailable;

  @override
  _JournalCardState createState() => _JournalCardState();
}

class _JournalCardState extends State<JournalCard> {

  var pdfFile;
  var image;
  bool isPDFLoaded = false;
  bool isLoadingPushed = false;

  @override
  Widget build(BuildContext context) {
    // Check if PDF loaded
    DefaultCacheManager().getFileFromCache(widget.pdfURL).then((file) {
      if (file != null) {
        pdfFile = file.file;
        setState(() {
          isPDFLoaded = true;
        });
      }
    });

    image = CachedNetworkImage(
        placeholder: (context, url) => CircularProgressIndicator(),
        imageUrl: widget.imgURL,
        width: 200.0,
        height: 290.0,
        fit: BoxFit.fitHeight
    );

    Widget titleSection = new Container(
      padding: const EdgeInsets.fromLTRB(10.0, 15, 10, 20),
      child: new Row(
        children: [
          new Expanded(
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                new Text(
                  widget.titleText,
                  textAlign: TextAlign.center,
                  style: new TextStyle(
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    FlatButton _buildButtonColumn(IconData icon, String label, bool isActive, Function onPressed) {
      Color color;
      if(isActive)
        color = Theme.of(context).primaryColor;
      else
        color = Theme.of(context).disabledColor;

      return FlatButton(
          onPressed: onPressed,
          child: new Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              new Icon(icon, color: color),
              new Container(
                margin: const EdgeInsets.only(top: 8.0),
                child: new Text(
                  label,
                  style: new TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w400,
                    color: color,
                  ),
                ),
              ),
            ],
          )
      );
    }

    final rightColumn = Container(
      padding: EdgeInsets.all(5.0),
      margin: EdgeInsets.all(5.0),
      child: widget.isAvailable ? Column( // Если журнал доступен, показываем кнопки управления
        children: [
          titleSection,
          _buildButtonColumn(
            Icons.chrome_reader_mode,
            'Читать',
            isPDFLoaded,
            () {
              if (isPDFLoaded)
              OpenFile.open(pdfFile.path);
            }
          ),
          _buildButtonColumn(
              isLoadingPushed ? Icons.autorenew : isPDFLoaded ? Icons.remove_circle : Icons.file_download,
              isLoadingPushed ? 'Загрузка...' : isPDFLoaded ? 'Удалить' : 'Загрузить',
              widget.isAvailable & ! isLoadingPushed,
                  () {
                    if (isPDFLoaded) {
                      DefaultCacheManager().removeFile(widget.pdfURL);
                      pdfFile = null;
                      setState(() {
                        isPDFLoaded = false;
                      });
                    }
                    else if(widget.isAvailable) {
                      DefaultCacheManager().downloadFile(widget.pdfURL).then(
                        (file) {
                          pdfFile = file.file;
                          setState(() {
                              isPDFLoaded = pdfFile != null;
                              isLoadingPushed = false;
                          });
                      });
                      setState(() {
                        isLoadingPushed = true;
                      });
                    }
                  }
          ),
          _buildButtonColumn(
            Icons.share,
            'Поделиться',
            true,
            () {
              Share.share(widget.pdfURL,);
            }
          )
        ],
        // widget.isAvailable ?
      ) : titleSection // Если журнал не доступен, показываем только название
    );

    return Container(
      margin: EdgeInsets.all(0),
      height:290,
      child: Card(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            image,
            Container(
              width: 200,
              margin: EdgeInsets.all(0),
              child: rightColumn,
            ),
          ],
        ),
      ),
    );
  }
}
