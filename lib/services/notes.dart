
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';

import '../models/notes_model.dart';

class NotesServices extends ChangeNotifier{
  List<Note> notes = [];
  final String _rpcUrl = Platform.isAndroid ? 'http://10.0.2.2:7545' : 'http://127.0.0.1:7545';
  final String _wscUrl = Platform.isAndroid ? 'http://10.0.2.2:7545' : 'ws://127.0.0.1:7545';
  bool isLoading = false;

  late Web3Client _web3client;
  late ContractAbi _abiCode;
  late EthereumAddress _ethereumAddress;
  late EthPrivateKey _ethPrivateKey;
  late DeployedContract _deployedContract;
  late ContractFunction _createNote;
  late ContractFunction _deleteNote;
  late ContractFunction _notes;
  late ContractFunction _noteCount;

  final String _privateKey = '75968fbb8da25267152e62fe308f47db29262522d0376e00cc22eee30d0f939d';

  NotesServices() {
    init();
  }

  Future<void> init() async {
    _web3client = Web3Client(
        _rpcUrl,
        http.Client(),
      socketConnector: () {
          return IOWebSocketChannel.connect(_wscUrl).cast<String>();
      }
    );
    await getABI();
    await getCredentials();
    await getDeployedContract();
  }

  Future<void> getABI() async {
    String abiFile = await rootBundle.loadString('build/contracts/NotesContract.json');
    var jsonABI = jsonDecode(abiFile);
    _abiCode = ContractAbi.fromJson(jsonEncode(jsonABI['abi']), 'NotesContract');
    _ethereumAddress = EthereumAddress.fromHex(jsonABI["networks"]["5777"]["address"]);
  }

  Future<void> getCredentials() async {
    _ethPrivateKey = EthPrivateKey.fromHex(_privateKey);
  }

  Future<void> getDeployedContract() async {
    _deployedContract = DeployedContract(_abiCode, _ethereumAddress);
    _createNote = _deployedContract.function('createNote');
    _deleteNote = _deployedContract.function('deleteNote');
    _notes = _deployedContract.function('notes');
    _noteCount = _deployedContract.function('noteCount');
    await fetchNotes();
  }

  Future<void> fetchNotes() async {
    List totalTaskList = await _web3client.call(
      contract: _deployedContract,
      function: _noteCount,
      params: [],
    );

    int totalTaskLen = totalTaskList[0].toInt();
    notes.clear();
    for (var i = 0; i < totalTaskLen; i++) {
      var temp = await _web3client.call(
          contract: _deployedContract,
          function: _notes,
          params: [BigInt.from(i)]);
      if (temp[1] != "") {
        notes.add(
          Note(
              temp[1],
              temp[2],
              (temp[0] as BigInt).toInt()),
        );
      }
    }

    notifyListeners();
  }

  Future<void> addNote(String title, String description) async {
    await _web3client.sendTransaction(
      _ethPrivateKey,
      Transaction.callContract(
        contract: _deployedContract,
        function: _createNote,
        parameters: [title, description],
      ),
    );
    fetchNotes();
  }

  Future<void> deleteNote(int id) async {
    await _web3client.sendTransaction(
      _ethPrivateKey,
      Transaction.callContract(
        contract: _deployedContract,
        function: _deleteNote,
        parameters: [BigInt.from(id)],
      ),
    );
    isLoading = true;
    notifyListeners();
    fetchNotes();
  }
}