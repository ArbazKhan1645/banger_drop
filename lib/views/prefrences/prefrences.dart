import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/widgets/bottom_navigation_bar/bottonBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class Prefrences extends StatefulWidget {
  const Prefrences({super.key, required this.fromSettings});
  final bool fromSettings;

  @override
  State<Prefrences> createState() => _PrefrencesState();
}

class _PrefrencesState extends State<Prefrences> {
  final genreMap = {
    'Hip Hop': ['Trap', 'Boom Bap', 'Drill', 'Lo-fi'],
    'Electronic': ['House', 'Trance', 'Dubstep', 'Techno'],
    'Rock': ['Alternative', 'Hard Rock', 'Indie Rock', 'Classic Rock'],
    'Pop': ['Dance Pop', 'Electropop', 'Synthpop'],
    'Jazz': ['Smooth Jazz', 'Bebop', 'Swing'],
    'Classical': ['Baroque', 'Romantic', 'Contemporary'],
    'Reggae': ['Roots', 'Dub', 'Dancehall'],
    'R&B': ['Neo Soul', 'Funk', 'Contemporary R&B'],
    'Country': ['Bluegrass', 'Honky Tonk', 'Modern Country'],
  };

  Map<String, Set<String>> selectedGenres = {};

  List<String> get selectedGenreList =>
      selectedGenres.entries
          .where((e) => e.value.isNotEmpty)
          .map((e) => e.key)
          .toList();

  List<String> get selectedSubGenreList =>
      selectedGenres.values.expand((e) => e).toSet().toList();

  void toggleGenre(String genre, bool isSelected) {
    setState(() {
      if (isSelected) {
        selectedGenres[genre] = genreMap[genre]!.toSet();
      } else {
        selectedGenres.remove(genre);
      }
    });
  }

  void toggleSubGenre(String genre, String subGenre, bool isSelected) {
    setState(() {
      final subList = selectedGenres[genre] ?? <String>{};
      if (isSelected) {
        subList.add(subGenre);
      } else {
        subList.remove(subGenre);
      }
      if (subList.isEmpty) {
        selectedGenres.remove(genre);
      } else {
        selectedGenres[genre] = subList;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          color: Colors.white,
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preferences',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Pick your favorite genres of music',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  final uid = FirebaseAuth.instance.currentUser!.uid;
                  final userRef = FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid);
                  final userSnap = await userRef.get();

                  final previouslySetGenres = userSnap.data()?['genres'] ?? [];

                  await userRef.update({
                    'genres': selectedGenreList,
                    'subGenres': selectedSubGenreList,
                  });

                  // ✅ Award 25 points if it's the first time setting preferences
                  if (previouslySetGenres.isEmpty &&
                      selectedGenreList.isNotEmpty) {
                    await userRef.set({
                      'points': FieldValue.increment(25),
                      'pointsHistory': FieldValue.arrayUnion([
                        {
                          'points': 25,
                          'timestamp': Timestamp.now(),
                          'reason': 'First time setting music preferences',
                        },
                      ]),
                    }, SetOptions(merge: true));

                    AppConstants.points =
                        ((int.tryParse(AppConstants.points.toString()) ?? 0) +
                                25)
                            .toString();
                  }

                  if (widget.fromSettings) {
                    Get.back();
                  } else {
                    Get.offAll(MainScreenView());
                  }
                },

                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: genreMap.length,
              itemBuilder: (context, index) {
                final genre = genreMap.keys.elementAt(index);
                final subGenres = genreMap[genre]!;
                final isGenreSelected = selectedGenres.containsKey(genre);

                return GenrePreferenceTile(
                  genre: genre,
                  subGenres: subGenres,
                  isGenreSelected: isGenreSelected,
                  selectedSubGenres: selectedGenres[genre] ?? {},
                  onGenreChanged: (val) => toggleGenre(genre, val),
                  onSubGenreChanged:
                      (sub, val) => toggleSubGenre(genre, sub, val),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class GenrePreferenceTile extends StatefulWidget {
  final String genre;
  final List<String> subGenres;
  final bool isGenreSelected;
  final Set<String> selectedSubGenres;
  final ValueChanged<bool> onGenreChanged;
  final Function(String, bool) onSubGenreChanged;

  const GenrePreferenceTile({
    super.key,
    required this.genre,
    required this.subGenres,
    required this.isGenreSelected,
    required this.selectedSubGenres,
    required this.onGenreChanged,
    required this.onSubGenreChanged,
  });

  @override
  State<GenrePreferenceTile> createState() => _GenrePreferenceTileState();
}

class _GenrePreferenceTileState extends State<GenrePreferenceTile> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: appColors.purple,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => isExpanded = !isExpanded),
            title: Text(
              widget.genre,
              style: const TextStyle(color: Colors.white),
            ),
            trailing: Checkbox(
              value: widget.isGenreSelected,
              activeColor: Colors.pink,
              onChanged: (val) => widget.onGenreChanged(val!),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children:
                    widget.subGenres.map((sub) {
                      return CheckboxListTile(
                        title: Text(
                          sub,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        value: widget.selectedSubGenres.contains(sub),
                        activeColor: Colors.pink,
                        onChanged:
                            widget.isGenreSelected
                                ? (val) => widget.onSubGenreChanged(sub, val!)
                                : null,
                      );
                    }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
