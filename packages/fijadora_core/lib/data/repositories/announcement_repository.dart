import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../domain/models/announcement.dart';
import '../services/supabase_service.dart';
import 'polling_select.dart';

abstract class AnnouncementRepository {
  Stream<List<Announcement>> streamAnnouncements();
  Future<List<Announcement>> getAnnouncements();
}

class SupabaseAnnouncementRepository implements AnnouncementRepository {
  SupabaseAnnouncementRepository(this._client);
  final sb.SupabaseClient _client;

  @override
  Stream<List<Announcement>> streamAnnouncements() {
    return pollingSelect<Announcement>(
      client: _client,
      table: 'announcements',
      fromJson: Announcement.fromJson,
      orderBy: 'created_at',
      ascending: false,
    );
  }

  @override
  Future<List<Announcement>> getAnnouncements() async {
    final data = await _client
        .from('announcements')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((json) => Announcement.fromJson(json)).toList();
  }
}

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  final repo = SupabaseAnnouncementRepository(SupabaseService.instance.client);
  return repo;
});
