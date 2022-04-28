/*
 * Copyright (c) TIKI Inc.
 * MIT license. See LICENSE file in root directory.
 */

import 'package:logging/logging.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import 'email_msg_model.dart';

class EmailMsgRepository {
  static const String _table = 'message';
  final _log = Logger('EmailRepositoryMsg');

  final Database _database;

  EmailMsgRepository(this._database);

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) =>
      _database.transaction(action);

  Future<void> createTable() =>
      _database.execute('CREATE TABLE IF NOT EXISTS $_table('
          'message_id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'ext_message_id TEXT NOT NULL, '
          'sender_email TEXT, '
          'received_date_epoch INTEGER, '
          'opened_date_epoch INTEGER, '
          'to_email TEXT NOT NULL, '
          'created_epoch INTEGER NOT NULL, '
          'modified_epoch INTEGER NOT NULL, '
          'UNIQUE (ext_message_id, to_email));');

  Future<int> upsert(List<EmailMsgModel> messages) async {
    if (messages.isNotEmpty) {
      Batch batch = _database.batch();
      for (var data in messages) {
        batch.rawInsert(
          'INSERT INTO $_table'
          '(ext_message_id, sender_email, received_date_epoch, opened_date_epoch, to_email, created_epoch, modified_epoch) '
          'VALUES(?1, ?2, ?3, ?4, ?5, strftime(\'%s\', \'now\') * 1000, strftime(\'%s\', \'now\') * 1000) '
          'ON CONFLICT(ext_message_id, to_email) DO UPDATE SET '
          'sender_email=IFNULL(?2, sender_email), '
          'received_date_epoch=IFNULL(?3, received_date_epoch), '
          'opened_date_epoch=IFNULL(?4, opened_date_epoch), '
          'modified_epoch=strftime(\'%s\', \'now\') * 1000 '
          'WHERE ext_message_id = ?2 AND to_email = ?5;',
          [
            data.extMessageId,
            data.sender?.email,
            data.receivedDate?.millisecondsSinceEpoch,
            data.openedDate?.millisecondsSinceEpoch,
            data.toEmail
          ],
        );
      }
      List res = await batch.commit(continueOnError: true);
      return res.length;
    } else {
      return 0;
    }
  }
}
