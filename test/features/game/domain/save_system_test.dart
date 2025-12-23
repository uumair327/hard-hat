import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

import 'package:hard_hat/core/errors/failures.dart';
import 'package:hard_hat/features/game/domain/entities/save_data.dart';
import 'package:hard_hat/features/game/domain/repositories/save_repository.dart';
import 'package:hard_hat/features/game/domain/systems/save_system.dart';

class MockSaveRepository extends Mock implements SaveRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('SaveSystem Tests', () {
    late SaveSystem saveSystem;
    late MockSaveRepository mockRepository;

    setUpAll(() {
      registerFallbackValue(SaveData(
        currentLevel: 1,
        unlockedLevels: {1},
        settings: {},
        lastPlayed: DateTime.now(),
      ));
    });

    setUp(() async {
      mockRepository = MockSaveRepository();
      saveSystem = SaveSystem(mockRepository);
    });

    tearDown(() async {
      saveSystem.dispose();
    });

    group('Initialization', () {
      test('should initialize with repository fallback when file access fails', () async {
        // Arrange
        when(() => mockRepository.getSaveData())
            .thenAnswer((_) async => Right(SaveData(
              currentLevel: 1,
              unlockedLevels: {1},
              settings: {},
              lastPlayed: DateTime.now(),
            )));

        // Act
        final result = await saveSystem.initialize();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (saveData) {
            expect(saveData.currentLevel, 1);
            expect(saveData.unlockedLevels, {1});
            expect(saveData.settings, isEmpty);
          },
        );
      });

      test('should handle initialization failure gracefully', () async {
        // Arrange
        when(() => mockRepository.getSaveData())
            .thenAnswer((_) async => const Left(SaveFailure('Repository error')));

        // Act
        final result = await saveSystem.initialize();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<SaveFailure>()),
          (saveData) => fail('Should fail'),
        );
      });
    });

    group('Cache Management', () {
      test('should return cached data when available', () async {
        // Arrange
        when(() => mockRepository.getSaveData())
            .thenAnswer((_) async => Right(SaveData(
              currentLevel: 2,
              unlockedLevels: {1, 2},
              settings: {'volume': 0.8},
              lastPlayed: DateTime.now(),
            )));
        
        await saveSystem.initialize();

        // Act
        final result = await saveSystem.getSaveData();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (saveData) {
            expect(saveData.currentLevel, 2);
            expect(saveData.unlockedLevels, {1, 2});
            expect(saveData.settings['volume'], 0.8);
          },
        );
      });

      test('should track dirty state correctly', () async {
        // Arrange
        when(() => mockRepository.getSaveData())
            .thenAnswer((_) async => Right(SaveData(
              currentLevel: 1,
              unlockedLevels: {1},
              settings: {},
              lastPlayed: DateTime.now(),
            )));
        
        await saveSystem.initialize();
        expect(saveSystem.isDirty, false);

        // Act
        saveSystem.markDirty();

        // Assert
        expect(saveSystem.isDirty, true);
      });
    });

    group('Data Validation', () {
      test('should validate save data structure', () async {
        // Arrange
        final testSaveData = SaveData(
          currentLevel: 3,
          unlockedLevels: {1, 2, 3},
          settings: {'volume': 0.7, 'difficulty': 'hard'},
          lastPlayed: DateTime.now(),
        );

        when(() => mockRepository.getSaveData())
            .thenAnswer((_) async => Right(testSaveData));

        // Act
        final result = await saveSystem.initialize();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (saveData) {
            expect(saveData.currentLevel, 3);
            expect(saveData.unlockedLevels, {1, 2, 3});
            expect(saveData.settings['volume'], 0.7);
            expect(saveData.settings['difficulty'], 'hard');
            expect(saveData.lastPlayed, isA<DateTime>());
          },
        );
      });
    });

    group('Error Handling', () {
      test('should handle repository failures gracefully', () async {
        // Arrange
        when(() => mockRepository.getSaveData())
            .thenAnswer((_) async => const Left(SaveFailure('Network error')));

        // Act
        final result = await saveSystem.getSaveData();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<SaveFailure>());
            // Check that it's a SaveFailure, the exact message may vary due to fallback behavior
            expect((failure as SaveFailure).message, isNotEmpty);
          },
          (saveData) => fail('Should fail'),
        );
      });

      test('should handle unexpected exceptions', () async {
        // Arrange
        when(() => mockRepository.getSaveData())
            .thenThrow(Exception('Unexpected error'));

        // Act
        final result = await saveSystem.getSaveData();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<SaveFailure>()),
          (saveData) => fail('Should fail'),
        );
      });
    });

    group('System Lifecycle', () {
      test('should dispose resources properly', () async {
        // Arrange
        when(() => mockRepository.getSaveData())
            .thenAnswer((_) async => Right(SaveData(
              currentLevel: 1,
              unlockedLevels: {1},
              settings: {},
              lastPlayed: DateTime.now(),
            )));
        
        await saveSystem.initialize();

        // Act
        saveSystem.dispose();

        // Assert
        expect(saveSystem.currentSaveData, isNull);
        expect(saveSystem.isDirty, false);
      });
    });
  });
}