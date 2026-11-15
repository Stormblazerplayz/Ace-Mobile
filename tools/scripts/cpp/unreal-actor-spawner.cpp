// @title Timed Actor Spawner
// @category Unreal Engine
// @kind Unreal C++ class
// @where In Unreal Editor use Tools > New C++ Class > Actor named ActorSpawner, replace the .h and .cpp with these two parts, build, drag one into the level and pick what to spawn in its Details panel.
// @keywords unreal actor spawner, ue5 c++ spawn enemies, unreal spawnactor timer, unreal wave spawner, tsubclassof spawn
// @about Spawns copies of any actor you choose every few seconds in a circle around itself, up to a maximum number at once.

// ===== ActorSpawner.h =====
#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "ActorSpawner.generated.h"  // this include must stay last

// Change YOURGAME_API to your project's name in capitals, like MYGAME_API.
UCLASS()
class YOURGAME_API AActorSpawner : public AActor
{
	GENERATED_BODY()

public:
	AActorSpawner();

protected:
	virtual void BeginPlay() override;
	virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;

	// Pick any Blueprint or class here, like an enemy or a coin.
	UPROPERTY(EditAnywhere, Category = "Spawner")
	TSubclassOf<AActor> ActorToSpawn;

	// Seconds between spawns.
	UPROPERTY(EditAnywhere, Category = "Spawner", meta = (ClampMin = "0.1"))
	float SpawnInterval = 3.f;

	// How far from the spawner things can appear.
	UPROPERTY(EditAnywhere, Category = "Spawner")
	float Radius = 500.f;

	// Stop spawning while this many are still alive.
	UPROPERTY(EditAnywhere, Category = "Spawner", meta = (ClampMin = "1"))
	int32 MaxAlive = 5;

	void SpawnOne();

private:
	FTimerHandle SpawnTimer;

	// Weak pointers become invalid by themselves when the actor is destroyed.
	TArray<TWeakObjectPtr<AActor>> Spawned;
};

// ===== ActorSpawner.cpp =====
#include "ActorSpawner.h"
#include "Engine/World.h"
#include "TimerManager.h"

AActorSpawner::AActorSpawner()
{
	PrimaryActorTick.bCanEverTick = false;  // the timer does the work, no Tick needed
	RootComponent = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
}

void AActorSpawner::BeginPlay()
{
	Super::BeginPlay();
	// Call SpawnOne every SpawnInterval seconds, over and over (the true means loop).
	GetWorldTimerManager().SetTimer(SpawnTimer, this, &AActorSpawner::SpawnOne, SpawnInterval, true);
}

void AActorSpawner::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
	GetWorldTimerManager().ClearTimer(SpawnTimer);
	Super::EndPlay(EndPlayReason);
}

void AActorSpawner::SpawnOne()
{
	if (!ActorToSpawn)
	{
		UE_LOG(LogTemp, Warning, TEXT("%s has nothing to spawn. Set Actor To Spawn in Details."), *GetName());
		return;
	}

	// Forget the ones that have been destroyed, then check the limit.
	Spawned.RemoveAll([](const TWeakObjectPtr<AActor>& A) { return !A.IsValid(); });
	if (Spawned.Num() >= MaxAlive)
	{
		return;
	}

	// A random spot on a flat circle around the spawner: pick a direction, then a distance.
	const FVector Direction = FRotator(0.f, FMath::FRandRange(0.f, 360.f), 0.f).Vector();
	const float Distance = FMath::FRandRange(0.f, Radius);
	const FVector Spot = GetActorLocation() + Direction * Distance;
	const FRotator Facing(0.f, FMath::FRandRange(0.f, 360.f), 0.f);

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AdjustIfPossibleButAlwaysSpawn;

	if (AActor* NewActor = GetWorld()->SpawnActor<AActor>(ActorToSpawn, Spot, Facing, Params))
	{
		Spawned.Add(NewActor);
	}
}
