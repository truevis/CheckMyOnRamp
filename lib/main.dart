import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

void main() => runApp(MaterialApp(home: WikipediaExplorer()));

class WikipediaExplorer extends StatefulWidget {
  @override
  _WikipediaExplorerState createState() => _WikipediaExplorerState();
}

class _WikipediaExplorerState extends State<WikipediaExplorer> {
  Completer<WebViewController> _controller = Completer<WebViewController>();
  String path =
      'https://dotfeeds.state.ma.us/TLImageHandler.ashx?mdotId=rLcBB6PCtYWI8AZBqwEoGBKXviJEdRf3C2JqOzfqEGMRyn3Zn3&fullJpeg=http://ie.trafficland.com/v1.0/1415/full?system=massdot&pubtoken=eae9194992826d4fe7dbb4b3740d0138bc73bb45953f9cc8d167fab4ead99004&refreshRate=2000&refreshVersion=0.9942211120638615';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: _bookmarkButton(),
        appBar: AppBar(
          title: const Text('Check My On-Ramp'),
          // This drop down menu demonstrates that Flutter widgets can be shown over the web view.
        ),
        body: Container(
          color: Colors.black,
          child: Column(children: <Widget>[
          Text(
            'Ramp Charlestown-Tobin to 93S/Storrow drive',
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Container(
            height: 200,
            child: WebView(
                initialUrl: path,
                onWebViewCreated: (WebViewController webViewController) {
                  _controller.complete(webViewController);
                }),
          )
        ]),
        ));
  }

  _bookmarkButton() {
    return FutureBuilder<WebViewController>(
      future: _controller.future,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> controller) {
        if (controller.hasData) {
          return FloatingActionButton(
            onPressed: () async {
              controller.data.reload();
            },
            child: Icon(Icons.refresh),
          );
        }
        return Container();
      },
    );
  }
}

class Menu extends StatelessWidget {
  Menu(this._webViewControllerFuture, this.favoritesAccessor);
  final Future<WebViewController> _webViewControllerFuture;
  // TODO(efortuna): Come up with a more elegant solution for an accessor to this than a callback.
  final Function favoritesAccessor;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _webViewControllerFuture,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> controller) {
        if (!controller.hasData) return Container();
        return PopupMenuButton<String>(
          onSelected: (String value) async {
            if (value == 'Email link') {
              var url = await controller.data.currentUrl();
              await launch(
                  'mailto:?subject=Check out this cool Wikipedia page&body=$url');
            } else {
              var newUrl = await Navigator.push(context,
                  MaterialPageRoute(builder: (BuildContext context) {
                return FavoritesPage(favoritesAccessor());
              }));
              Scaffold.of(context).removeCurrentSnackBar();
              if (newUrl != null) controller.data.loadUrl(newUrl);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
                const PopupMenuItem<String>(
                  value: 'Email link',
                  child: Text('Email link'),
                ),
                const PopupMenuItem<String>(
                  value: 'See Favorites',
                  child: Text('See Favorites'),
                ),
              ],
        );
      },
    );
  }
}

class FavoritesPage extends StatelessWidget {
  FavoritesPage(this.favorites);
  final Set<String> favorites;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Favorite pages')),
      body: ListView(
          children: favorites
              .map((url) => ListTile(
                  title: Text(url), onTap: () => Navigator.pop(context, url)))
              .toList()),
    );
  }
}

class NavigationControls extends StatelessWidget {
  const NavigationControls(this._webViewControllerFuture)
      : assert(_webViewControllerFuture != null);

  final Future<WebViewController> _webViewControllerFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: _webViewControllerFuture,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> snapshot) {
        final bool webViewReady =
            snapshot.connectionState == ConnectionState.done;
        final WebViewController controller = snapshot.data;
        return Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: !webViewReady
                  ? null
                  : () => navigate(context, controller, goBack: true),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: !webViewReady
                  ? null
                  : () => navigate(context, controller, goBack: false),
            ),
          ],
        );
      },
    );
  }

  navigate(BuildContext context, WebViewController controller,
      {bool goBack: false}) async {
    bool canNavigate =
        goBack ? await controller.canGoBack() : await controller.canGoForward();
    if (canNavigate) {
      goBack ? controller.goBack() : controller.goForward();
    } else {
      Scaffold.of(context).showSnackBar(
        SnackBar(
            content: Text("No ${goBack ? 'back' : 'forward'} history item")),
      );
    }
  }
}
