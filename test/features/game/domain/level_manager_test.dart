import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:flame/components.dart';

import 'package:hard_hat/features/game/domain/systems/level_manager.dart';
import 'package:hard_hat/features/game/domain/systems/entity_manager.dart';
import 'package:hard_hat/features/game/domain/repositories/level_repository.dart';
import 'package:hard_hat/features/game/domain/entities/level.dart';
import 'package:hard_hat/features/game/domain/entities/tile.dart';
import 'package:hard_hat/features/game/domain/entities/game_entity.dart';
import 'package:hard_hat/features/game/domain/entities/player_entity.dart';
import 'package:hard_hat/core/errors/failures.dart';

class MockLevelRepository extends Mock implements LevelRepository {}
class MockEntityManager extends Mock implements EntityManager {}
class FakeGameEntity extends Fake implements GameEntity {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeGameEntity());
  });

  group('LevelManager Tests', () {
    late LevelManager levelManager;
    late MockLevelRepository mockLevelRepository;
    late MockEntityManager mockEntityManager;

    setUp(() {
      mockLevelRepository = MockLevelRepository();
      mockEntityManager = MockEntityManager();
      
      // Mock getEntitiesOfType to return empty list by default
      when(() => mockEntityManager.getEntitiesOfType<PlayerEntity>())
          .thenReturn(const Iterable<PlayerEntity>.empty());
      
      levelManager = LevelManager(
        levelRepository: mockLevelRepository,
        entityManager: mockEntityManager,
      );
    });

    group('Level Loading', () {
      test('should load level successfully', () async {
        // Arrange
        const levelId = 1;
        final testLevel = Level(
          id: levelId,
          name: 'Test Level',
          size: Vector2(800, 600),
          tiles: [],
          playerSpawn: Vector2(50, 500),
          cameraMin: Vector2.zero(),
          cameraMax: Vector2(800, 600),
          elements: [],
        );

        when(() => mockLevelRepository.getLevel(levelId))
            .thenAnswer((_) async => Right(testLevel));

        // Act
        await levelManager.loadLevel(levelId);

        // Assert
        expect(levelManager.currentLevel, equals(testLevel));
        expect(levelManager.isLevelLoaded, isTrue);
        verify(() => mockLevelRepository.getLevel(levelId)).called(1);
      });

      test('should handle level loading failure', () async {
        // Arrange
        const levelId = 1;
        final failure = LevelLoadFailure('Level not found');

        when(() => mockLevelRepository.getLevel(levelId))
            .thenAnswer((_) async => Left(failure));

        Failure? receivedFailure;
        levelManager.onLevelLoadError = (failure) {
          receivedFailure = failure;
        };

        // Act
        await levelManager.loadLevel(levelId);

        // Assert
        expect(levelManager.currentLevel, isNull);
        expect(levelManager.isLevelLoaded, isFalse);
        expect(receivedFailure, equals(failure));
      });
    });

    group('Level Properties', () {
      test('should provide level properties', () async {
        // Arrange
        const levelId = 1;
        final testLevel = Level(
          id: levelId,
          name: 'Test Level',
          size: Vector2(800, 600),
          tiles: [],
          playerSpawn: Vector2(50, 500),
          cameraMin: Vector2.zero(),
          cameraMax: Vector2(800, 600),
          elements: [],
        );

        when(() => mockLevelRepository.getLevel(levelId))
            .thenAnswer((_) async => Right(testLevel));

        await levelManager.loadLevel(levelId);

        // Act & Assert
        expect(levelManager.currentLevelId, equals(levelId));
        expect(levelManager.currentLevelName, equals('Test Level'));
        expect(levelManager.levelSize, equals(Vector2(800, 600)));
        expect(levelManager.playerSpawn, equals(Vector2(50, 500)));
        expect(levelManager.cameraMin, equals(Vector2.zero()));
        expect(levelManager.cameraMax, equals(Vector2(800, 600)));
      });
    });

    group('Level State Management', () {
      test('should clear level when loading new level', () async {
        // Arrange
        const levelId1 = 1;
        const levelId2 = 2;
        final testLevel1 = Level(
          id: levelId1,
          name: 'Test Level 1',
          size: Vector2(800, 600),
          tiles: [],
          playerSpawn: Vector2(50, 500),
          cameraMin: Vector2.zero(),
          cameraMax: Vector2(800, 600),
          elements: [],
        );
        final testLevel2 = Level(
          id: levelId2,
          name: 'Test Level 2',
          size: Vector2(1200, 800),
          tiles: [],
          playerSpawn: Vector2(100, 700),
          cameraMin: Vector2.zero(),
          cameraMax: Vector2(1200, 800),
          elements: [],
        );

        when(() => mockLevelRepository.getLevel(levelId1))
            .thenAnswer((_) async => Right(testLevel1));
        when(() => mockLevelRepository.getLevel(levelId2))
            .thenAnswer((_) async => Right(testLevel2));

        // Act
        await levelManager.loadLevel(levelId1);
        expect(levelManager.currentLevelId, equals(levelId1));

        await levelManager.loadLevel(levelId2);

        // Assert
        expect(levelManager.currentLevelId, equals(levelId2));
        expect(levelManager.currentLevelName, equals('Test Level 2'));
        expect(levelManager.levelSize, equals(Vector2(1200, 800)));
      });

      test('should report no level loaded initially', () {
        // Assert
        expect(levelManager.isLevelLoaded, isFalse);
        expect(levelManager.currentLevel, isNull);
        expect(levelManager.currentLevelId, isNull);
        expect(levelManager.currentLevelName, isNull);
      });
    });
  });
}