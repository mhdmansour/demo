import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

typedef FetchDataFunction = Future<List<String>> Function(
    BehaviorSubject<List<String>> subject, int currentPage, int pageSize, int pageIndex, bool delayed);

class InfiniteScrollPagination extends StatefulWidget {
  final ScrollController scrollController;
  final FetchDataFunction fetchDataFunction;

  const InfiniteScrollPagination({Key? key, required this.scrollController, required this.fetchDataFunction}) : super(key: key);

  @override
  State<InfiniteScrollPagination> createState() => _InfiniteScrollPaginationState();
}

class _InfiniteScrollPaginationState extends State<InfiniteScrollPagination> {
  int _currentPage = 0;
  final int _pageSize = 7;
  late final ScrollController _scrollController;
  bool _isFetchingData = false;
  late BehaviorSubject<List<String>> source1Subject;
  late BehaviorSubject<List<String>> source2Subject;
  late BehaviorSubject<List<String>> source3Subject;
  TextEditingController editingController = TextEditingController();
  List<String> _filteredList = [];

  Future<void> _fetchPaginatedData(int pageIndex, bool delayed) async {
    if (_isFetchingData) {
      // Avoid fetching new data while already fetching
      return;
    }
    try {
      _isFetchingData = true;
      setState(() {});
      final items = await widget.fetchDataFunction(source1Subject, pageIndex == -1 ? _currentPage : 0, _pageSize, pageIndex, delayed);
      source1Subject.add(items);
      source2Subject.add(items);
      source3Subject.add(items);
      pageIndex == -1 ? _currentPage++ : _currentPage = 1;
    } catch (e) {
      source1Subject.addError(e);
    } finally {
      // Set to false when data fetching is complete
      _isFetchingData = false;
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    source1Subject = BehaviorSubject<List<String>>();
    source2Subject = BehaviorSubject<List<String>>();
    source3Subject = BehaviorSubject<List<String>>();
    _scrollController = widget.scrollController;
    _fetchPaginatedData(-1, true);

    _scrollController.addListener(() {
      _scrollController.addListener(() {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;
        if (currentScroll == maxScroll) {
          // When the last item is fully visible, load the next page.
          _fetchPaginatedData(-1, true);
        }
      });
    });
  }

  void clearAllSubject() {
    source1Subject.add([]);
    source2Subject.add([]);
    source3Subject.add([]);
  }

  final itemCategory = ["even"];
  List<String> selectedItem = [];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: CombineLatestStream.combine3(
        source1Subject.stream,
        source2Subject.stream,
        source3Subject.stream,
        (data1, data2, data3) => [...data1, ...data2, ...data3],
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Display a loading indicator
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // Handle errors
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // Display a message when there is no data
          return const Center(child: Text('No data available.'));
        } else {
          List<String>? items = snapshot.data!;
          return ListView(
            shrinkWrap: true,
            controller: _scrollController,
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      onChanged: (value) {
                        if (value.isEmpty) {
                          source1Subject.add([]);
                          _fetchPaginatedData(0, false);
                        } else {
                          _filteredList = items.where((item) => item.toLowerCase().contains(value.toLowerCase())).toList();
                          if (_filteredList.isNotEmpty) {
                            clearAllSubject();
                            source1Subject.add(_filteredList);
                          }
                        }
                      },
                      controller: editingController,
                      decoration: const InputDecoration(
                          labelText: "Search",
                          hintText: "Search",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(25.0)))),
                    ),
                  ),
                  IconButton(
                      onPressed: () {
                        clearAllSubject();
                        List<String> temp = items.reversed.toList();
                        source1Subject.add(temp);
                      },
                      icon: const Icon(
                        Icons.swap_vert,
                        size: 30,
                      )),
                  IconButton(
                      onPressed: () {
                        clearAllSubject();
                        _fetchPaginatedData(0, false);
                      },
                      icon: const Icon(
                        Icons.refresh,
                        size: 30,
                      )),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: itemCategory
                        .map((e) => Padding(
                            padding: const EdgeInsets.only(top: 20, left: 20, bottom: 10),
                            child: ChoiceChip(
                              label: Text(e),
                              selected: selectedItem.contains(e),
                              showCheckmark: true,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedItem.add(e);
                                    List<String> filteredList = items.where((item) => RegExp(r'\d*[02468]').hasMatch(item)).toList();
                                    if (filteredList.isNotEmpty) {
                                      clearAllSubject();
                                      source1Subject.add(filteredList);
                                    }
                                  } else {
                                    selectedItem.remove(e);
                                    source1Subject.add([]);
                                    _fetchPaginatedData(0, false);
                                  }
                                });
                              },
                            )))
                        .toList(),
                  )
                ],
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items!.length,
                itemBuilder: (context, index) {
                  return displayData(items![index]);
                },
              ),
              if (_isFetchingData)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                )),
            ],
          );
        }
      },
    );
  }

  Widget displayData(String data) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Text(data),
    );
  }

  @override
  void dispose() {
    // _dataStreamController.close();
    //we do not have control cover the _scrollController so it should not be disposed here
    // _scrollController.dispose();
    super.dispose();
  }
}
