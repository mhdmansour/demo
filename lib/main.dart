import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';

import 'infinite_scroll_pagination.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Demo',
      home: InfiniteScroll(),
    );
  }
}

class InfiniteScroll extends StatelessWidget {
  const InfiniteScroll({Key? key}) : super(key: key);


  Future<List<String>> fetchData(BehaviorSubject<List<String>> subject,int currentPage, int pageSize, int pageIndex,bool delayed) async {
      if(delayed == true) {await Future.delayed(Duration(seconds: 3));}
      List<String> newData = List.generate(pageSize, (index) => 'Data ${currentPage * pageSize + index + 1}');
      return newData;
    }


  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infinite Scroll Widget'),


    ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InfiniteScrollPagination(
                scrollController: scrollController,
                fetchDataFunction: fetchData,
              ),
            ),
          ],
        ),
      ),
    );
  }
}