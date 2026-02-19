import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/helper/shared_prefrences_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:banger_drop/consts/consts.dart';
import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_typedefs/rx_typedefs.dart';

class BangerAppbarWidget extends StatefulWidget {
  final VoidCallback onBackPressed;
  final VoidCallback onSharePressed;
  final String id; // 👈 ID of the current item (playlist/song/etc.)

  const BangerAppbarWidget({
    super.key,
    required this.onBackPressed,
    required this.onSharePressed,
    required this.id,
  });

  @override
  State<BangerAppbarWidget> createState() => _BangerAppbarWidgetState();
}

class _BangerAppbarWidgetState extends State<BangerAppbarWidget> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    await SharedPreferencesHelper.init();
    List<String> favList = SharedPreferencesHelper.getStringList('fav') ?? [];

    setState(() {
      isFavorite = favList.contains(widget.id);
    });
  }

  Future<void> _toggleFavorite() async {
    List<String> favList = SharedPreferencesHelper.getStringList('fav') ?? [];
    print(widget.id);
    print(
      '================================---======================----==================',
    );
    setState(() {
      if (isFavorite) {
        favList.remove(widget.id);
        isFavorite = false;
      } else {
        favList.add(widget.id);
        isFavorite = true;
      }
    });

    await SharedPreferencesHelper.setStringList('fav', favList);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: widget.onBackPressed,
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: appColors.white),
        ),
        Row(
          children: [
            IconButton(
              onPressed: _toggleFavorite,
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: appColors.white,
              ),
            ),
            IconButton(
              onPressed: widget.onSharePressed,
              icon: Icon(Icons.share_outlined, color: appColors.white),
            ),
          ],
        ),
      ],
    );
  }
}

class PlaylisAppbarWidget extends StatefulWidget {
  const PlaylisAppbarWidget({
    super.key,
    required this.onBackPressed,
    required this.onSharePressed,
    required this.id,
  });

  final Callback onBackPressed;
  final Callback onSharePressed;
  final String id;

  @override
  State<PlaylisAppbarWidget> createState() => _PlaylisAppbarWidgetState();
}

class _PlaylisAppbarWidgetState extends State<PlaylisAppbarWidget> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteState();
  }

  Future<void> _loadFavoriteState() async {
    List<String> favList =
        SharedPreferencesHelper.getStringList('favPlayList') ?? [];
    setState(() {
      isFavorite = favList.contains(widget.id);
    });
  }

  Future<void> _toggleFavorite() async {
    List<String> favList =
        SharedPreferencesHelper.getStringList('favPlayList') ?? [];

    setState(() {
      if (isFavorite) {
        favList.remove(widget.id);
        isFavorite = false;
      } else {
        favList.add(widget.id);
        isFavorite = true;
      }
    });
    print(favList);
    await SharedPreferencesHelper.setStringList('favPlayList', favList);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: widget.onBackPressed,
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: appColors.white),
        ),
        // Row(
        //   children: [
        //     IconButton(
        //       onPressed: _toggleFavorite,
        //       icon: Icon(
        //         isFavorite ? Icons.star : Icons.star_border,
        //         color: appColors.white,
        //       ),
        //     ),
        //     IconButton(
        //       onPressed: widget.onSharePressed,
        //       icon: Icon(Icons.share_outlined, color: appColors.white),
        //     ),
        //   ],
        // ),
      ],
    );
  }
}

class MiniFavShareWidget extends StatefulWidget {
  final String id; // ID of the item
  final bool isPlaylist; // true = playlist, false = banger
  final VoidCallback onSharePressed;

  const MiniFavShareWidget({
    super.key,
    required this.id,
    required this.onSharePressed,
    this.isPlaylist = false,
  });

  @override
  State<MiniFavShareWidget> createState() => _MiniFavShareWidgetState();
}

class _MiniFavShareWidgetState extends State<MiniFavShareWidget> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    await SharedPreferencesHelper.init();
    final key = 'favPlayList';
    List<String> favList = SharedPreferencesHelper.getStringList(key) ?? [];
    print('====================================$key');
    setState(() {
      isFavorite = favList.contains(widget.id);
    });
  }

  Future<void> _toggleFavorite() async {
    final key = 'favPlayList';
    List<String> favList = SharedPreferencesHelper.getStringList(key) ?? [];
    print(key);
    setState(() {
      if (isFavorite) {
        favList.remove(widget.id);
        isFavorite = false;
      } else {
        favList.add(widget.id);
        isFavorite = true;
      }
    });

    await SharedPreferencesHelper.setStringList(key, favList);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: _toggleFavorite,
          icon: Icon(
            isFavorite ? Icons.star : Icons.star_border,
            color: appColors.white,
          ),
        ),
        IconButton(
          onPressed: widget.onSharePressed,
          icon: Icon(Icons.share_outlined, color: appColors.white),
        ),
      ],
    );
  }
}
