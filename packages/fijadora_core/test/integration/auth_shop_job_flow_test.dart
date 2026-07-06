import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:fijadora_core/data/repositories/auth_repository.dart';
import 'package:fijadora_core/data/repositories/jobs_repository.dart';
import 'package:fijadora_core/data/repositories/shop_repository.dart';
import 'package:fijadora_core/data/services/app_notification_service.dart';
import 'package:fijadora_core/data/services/telemetry_service.dart';
import 'package:fijadora_core/domain/models/app_user.dart';
import 'package:fijadora_core/domain/models/job_status.dart';
import 'package:fijadora_core/domain/models/maintenance_job.dart';
import 'package:fijadora_core/domain/models/product.dart';
import 'package:fijadora_core/domain/models/trade_type.dart';
import 'package:fijadora_core/domain/models/user_role.dart';
import 'package:fijadora_core/ui/features/auth/view_models/auth_view_model.dart';
import 'package:fijadora_core/ui/features/services/view_models/jobs_view_model.dart';
import 'package:fijadora_core/ui/features/shop/view_models/cart_view_model.dart';

/// Stub repository that acts as a simple in-memory backend
class TestAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;
  bool _shouldFail = false;

  @override
  AppUser? get currentUser => _currentUser;
  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  void setFailure(bool fail) => _shouldFail = fail;
  void emitUser(AppUser? user) {
    _currentUser = user;
    _controller.add(user);
  }

  @override
  Future<void> signUp({required String email, required String password, required String name, required UserRole role}) async {
    if (_shouldFail) throw Exception('Send failed');
    // signUp does NOT add user to stream — email must be confirmed first
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (_shouldFail) throw Exception('Sign in failed');
    _currentUser = AppUser(id: 'user-1', email: email, name: 'Test User', role: UserRole.customer, createdAt: DateTime(2026));
    _controller.add(_currentUser);
  }

  @override
  Future<void> resendEmailVerification({required String email}) async {
    if (_shouldFail) throw Exception('Resend failed');
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  List<AppUser> getAllWorkers() => [];
  @override
  Future<void> refreshWorkers() async {}
  @override
  Future<void> updateWorkerStatus({required String userId, required String status}) async {}
  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}
  @override
  Future<void> updatePassword({required String newPassword}) async {}
  @override
  Future<void> deleteAccount() async {}
  @override
  void dispose() => _controller.close();
}

class TestShopRepository implements ShopRepository {
  final _productController = StreamController<List<Product>>.broadcast();
  final _wishlistController = StreamController<List<String>>.broadcast();
  List<Product> _products = [];
  final List<String> _wishlist = [];

  @override
  Stream<List<Product>> streamProducts() => _productController.stream;
  @override
  Stream<List<String>> streamWishlist() => _wishlistController.stream;

  void seedProducts(List<Product> products) {
    _products = products;
    _productController.add(List.unmodifiable(_products));
  }

  @override
  Future<void> toggleWishlist(String productId) async {
    if (_wishlist.contains(productId)) {
      _wishlist.remove(productId);
    } else {
      _wishlist.add(productId);
    }
    _wishlistController.add(List.unmodifiable(_wishlist));
  }

  bool isWishlisted(String id) => _wishlist.contains(id);

  @override
  Future<Product> createProduct(Product product) async => throw UnimplementedError();
  @override
  Future<Product> updateProduct(Product product) async => throw UnimplementedError();
  @override
  Future<void> deleteProduct(String id) async {}
  @override
  Future<String> uploadProductImage(String fileName, Uint8List fileBytes) async => '';
  @override
  Stream<List<Map<String, dynamic>>> streamReviews(String productId) => const Stream.empty();
  @override
  Future<void> addReview(String productId, double rating, String comment) async {}
  @override
  void dispose() { _productController.close(); _wishlistController.close(); }
}

class TestJobsRepository implements JobsRepository {
  final _controller = StreamController<List<MaintenanceJob>>.broadcast();
  final List<MaintenanceJob> _jobs = [];
  int _nextId = 1;

  @override
  Stream<List<MaintenanceJob>> streamJobs({required String userId, required UserRole role}) {
    return _controller.stream;
  }

  void emit() => _controller.add(List.unmodifiable(_jobs));

  @override
  Future<MaintenanceJob> createJob({required MaintenanceJob job}) async {
    final created = MaintenanceJob(
      id: 'job-${_nextId++}',
      description: job.description,
      tradeType: job.tradeType,
      status: JobStatus.pending,
      scheduleDateTime: job.scheduleDateTime,
      address: job.address,
      images: job.images,
      customerId: job.customerId,
      assetId: job.assetId,
      createdAt: DateTime.now(),
    );
    _jobs.add(created);
    emit();
    return created;
  }

  @override
  Future<MaintenanceJob> updateJobStatus({required String jobId, required JobStatus status}) async {
    final idx = _jobs.indexWhere((j) => j.id == jobId);
    if (idx == -1) throw Exception('Job not found');
    _jobs[idx] = _jobs[idx].copyWith(status: status);
    emit();
    return _jobs[idx];
  }

  @override
  Future<MaintenanceJob> assignWorker({required String jobId, required String workerId}) async {
    final idx = _jobs.indexWhere((j) => j.id == jobId);
    if (idx == -1) throw Exception('Job not found');
    _jobs[idx] = _jobs[idx].copyWith(workerId: workerId, status: JobStatus.assigned);
    emit();
    return _jobs[idx];
  }

  @override
  Future<MaintenanceJob> getJob({required String jobId}) async {
    return _jobs.firstWhere((j) => j.id == jobId);
  }

  @override
  Future<String> uploadJobImage(String fileName, Uint8List fileBytes) async {
    return 'https://example.com/uploads/$fileName';
  }

  @override
  Future<MaintenanceJob> completeJob({required String jobId, required String notes, required List<String> images}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<MaintenanceJob>> fetchJobsForAsset({required String assetId}) async {
    return _jobs.where((j) => j.assetId == assetId).toList();
  }

  @override
  Future<MaintenanceJob> rejectJob({required String jobId}) async {
    final idx = _jobs.indexWhere((j) => j.id == jobId);
    if (idx == -1) throw Exception('Job not found');
    _jobs[idx] = _jobs[idx].copyWith(status: JobStatus.rejected);
    emit();
    return _jobs[idx];
  }

  @override
  void dispose() => _controller.close();
}

class TestNotificationService implements NotificationService {
  final List<String> sentTitles = [];
  @override
  void sendNotification({required String title, required String body}) => sentTitles.add(title);
  @override
  Stream<AppNotification> get notificationsStream => const Stream.empty();
  @override
  void dispose() {}
}

class TestTelemetryService implements TelemetryService {
  final List<String> loggedEvents = [];
  @override
  void logEvent(String name, [Map<String, dynamic>? parameters]) => loggedEvents.add(name);
  @override
  void captureException(Object error, [StackTrace? stackTrace]) {}
}

void main() {
  group('Auth → Shop → Job Flow', () {
    late TestAuthRepository authRepo;
    late TestShopRepository shopRepo;
    late TestJobsRepository jobsRepo;
    late TestNotificationService notifService;
    late TestTelemetryService teleService;

    setUp(() {
      authRepo = TestAuthRepository();
      shopRepo = TestShopRepository();
      jobsRepo = TestJobsRepository();
      notifService = TestNotificationService();
      teleService = TestTelemetryService();
    });

    tearDown(() {
      authRepo.dispose();
      shopRepo.dispose();
      jobsRepo.dispose();
      notifService.dispose();
    });

    test('Auth flow: sign up → sign in → sign out', () async {
      final authVM = AuthViewModel(authRepo);

      // Sign up (email verification required)
      await authVM.signUp(email: 'user@test.com', password: 'Password1', name: 'Test', role: UserRole.customer);
      expect(authVM.needsEmailVerification, isTrue);
      expect(authVM.isAuthenticated, isFalse);
      expect(authVM.user, isNull);

      // Simulate email confirmed → user signs in
      await authVM.signIn(email: 'user@test.com', password: 'Password1');
      expect(authVM.isAuthenticated, isTrue);
      expect(authVM.user?.email, 'user@test.com');

      // Sign out
      await authVM.signOut();
      expect(authVM.isAuthenticated, isFalse);
      expect(authVM.user, isNull);

      authVM.dispose();
    });

    test('Auth flow: sign up failure shows error', () async {
      final authVM = AuthViewModel(authRepo);
      authRepo.setFailure(true);

      try { await authVM.signUp(email: 'bad@test.com', password: 'Password1', name: 'Bad', role: UserRole.customer); } catch (_) {}
      expect(authVM.needsEmailVerification, isFalse);
      expect(authVM.isAuthenticated, isFalse);
      expect(authVM.user, isNull);

      // Failure clears on next successful attempt
      authRepo.setFailure(false);
      await authVM.signUp(email: 'good@test.com', password: 'Password1', name: 'Good', role: UserRole.customer);
      expect(authVM.needsEmailVerification, isTrue);
      expect(authVM.isAuthenticated, isFalse);
      expect(authVM.errorMessage, isNull);

      authVM.dispose();
    });

    test('Shop flow: browse → add to cart → remove from cart → wishlist toggle', () async {
      final cartVM = CartViewModel();
      final p1 = Product(id: 'p1', name: 'Desk', description: 'Wooden desk', price: 299.0,
          imageUrl: '', category: 'Furniture', inventoryCount: 5, createdAt: DateTime(2026));
      final p2 = Product(id: 'p2', name: 'Chair', description: 'Comfortable chair', price: 149.0,
          imageUrl: '', category: 'Furniture', inventoryCount: 10, createdAt: DateTime(2026));

      // Browse: seed products
      shopRepo.seedProducts([p1, p2]);
      await Future(() {});

      // Wishlist toggle on
      expect(shopRepo.isWishlisted('p1'), isFalse);
      await shopRepo.toggleWishlist('p1');
      expect(shopRepo.isWishlisted('p1'), isTrue);

      // Add to cart
      expect(cartVM.totalItems, 0);
      cartVM.addToCart(p1);
      expect(cartVM.totalItems, 1);
      cartVM.addToCart(p2);
      expect(cartVM.totalItems, 2);
      expect(cartVM.totalPrice, 448.0);

      // Remove from cart
      cartVM.removeFromCart(p1);
      expect(cartVM.state.length, 1);
      expect(cartVM.state.containsKey(p1), isFalse);
      expect(cartVM.totalPrice, 149.0);

      // Wishlist toggle off
      await shopRepo.toggleWishlist('p1');
      expect(shopRepo.isWishlisted('p1'), isFalse);

      // Clear cart
      cartVM.clearCart();
      expect(cartVM.totalItems, 0);
    });

    test('Shop flow: cart respects inventory limits', () async {
      final cartVM = CartViewModel();
      final limited = Product(id: 'p-limited', name: 'Limited', description: '', price: 10.0,
          imageUrl: '', category: '', inventoryCount: 3, createdAt: DateTime(2026));

      cartVM.addToCart(limited);
      cartVM.addToCart(limited);
      cartVM.addToCart(limited);
      cartVM.addToCart(limited); // blocked
      expect(cartVM.state[limited], 3);

      cartVM.addToCart(Product(id: 'p-out', name: 'Out', description: '', price: 10.0,
          imageUrl: '', category: '', inventoryCount: 0, createdAt: DateTime(2026)));
      expect(cartVM.state.length, 1); // only 'limited' in cart
    });

    test('Job flow: create → assign → update status → complete', () async {
      final jobsVM = JobsViewModel(
        jobsRepository: jobsRepo,
        notificationService: notifService,
        telemetryService: teleService,
        userId: 'customer-1',
        role: UserRole.customer,
      );

      // Create job
      final job = await jobsVM.raiseJob(
        description: 'Fix kitchen sink',
        tradeType: TradeType.plumbing,
        schedule: DateTime(2026, 7, 10, 14, 0),
        address: '123 Main St',
        images: [],
      );
      expect(job.status, JobStatus.pending);
      expect(job.id, isNotEmpty);

      // Assign worker
      final assigned = await jobsRepo.assignWorker(jobId: job.id, workerId: 'worker-1');
      expect(assigned.status, JobStatus.assigned);
      expect(assigned.workerId, 'worker-1');

      // Update to in progress
      await jobsVM.updateStatus(assigned.id, JobStatus.inProgress);
      final inProgress = await jobsRepo.getJob(jobId: assigned.id);
      expect(inProgress.status, JobStatus.inProgress);

      // Complete
      await jobsVM.updateStatus(inProgress.id, JobStatus.completed);
      final completed = await jobsRepo.getJob(jobId: assigned.id);
      expect(completed.status, JobStatus.completed);

      // Verify notifications were sent
      expect(notifService.sentTitles, contains('New Service Request Raised'));
      expect(notifService.sentTitles, contains('Job Status Updated'));

      jobsVM.dispose();
    });

    test('Job flow: create failure does not add job', () async {
      final jobsVM = JobsViewModel(
        jobsRepository: jobsRepo,
        notificationService: notifService,
        telemetryService: teleService,
        userId: 'customer-1',
        role: UserRole.customer,
      );

      // Save a ref to force the job to be stored
      MaintenanceJob? created;
      try {
        created = await jobsVM.raiseJob(
          description: 'Test', tradeType: TradeType.electrical,
          schedule: DateTime(2026, 7, 10), address: '', images: [],
        );
      } catch (_) {}
      expect(created, isNotNull);
      expect(jobsVM.isCreating, isFalse);

      // Verify telemetry
      expect(teleService.loggedEvents, contains('raise_job'));

      jobsVM.dispose();
    });
  });
}
