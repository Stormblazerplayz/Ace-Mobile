// @title Kill Volume (Kill Brick)
// @category Unreal Engine
// @kind Unreal C++ class
// @where In Unreal Editor use Tools > New C++ Class > Actor named KillVolume, then replace the .h and .cpp with these two parts, build, and drag it into your level where players should die.
// @keywords unreal kill volume, unreal kill brick, ue5 c++ death zone, unreal lava that kills the player, unreal overlap kill
// @about An invisible box that kills any pawn or character that touches it, then respawns players at the Player Start after a second.

// ===== KillVolume.h =====
#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "KillVolume.generated.h"  // this include must stay last

class UBoxComponent;
class UPrimitiveComponent;

// Change YOURGAME_API to your project's name in capitals, like MYGAME_API.
UCLASS()
class YOURGAME_API AKillVolume : public AActor
{
	GENERATED_BODY()

public:
	AKillVolume();

protected:
	virtual void BeginPlay() override;

	// The box that does the killing. Change its size with Box Extent in Details.
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Kill Volume")
	TObjectPtr<UBoxComponent> Box;

	// Bring players back at the Player Start after they die.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Kill Volume")
	bool bRespawnPlayers = true;

	// Seconds to wait before respawning.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Kill Volume", meta = (ClampMin = "0.1"))
	float RespawnDelay = 1.f;

	// Runs when something starts touching the box. UFUNCTION is needed for AddDynamic.
	UFUNCTION()
	void OnBoxBeginOverlap(UPrimitiveComponent* OverlappedComp, AActor* OtherActor,
		UPrimitiveComponent* OtherComp, int32 OtherBodyIndex, bool bFromSweep,
		const FHitResult& SweepResult);
};

// ===== KillVolume.cpp =====
#include "KillVolume.h"
#include "Components/BoxComponent.h"
#include "Engine/World.h"
#include "GameFramework/Controller.h"
#include "GameFramework/GameModeBase.h"
#include "GameFramework/Pawn.h"
#include "GameFramework/PlayerController.h"
#include "TimerManager.h"

AKillVolume::AKillVolume()
{
	PrimaryActorTick.bCanEverTick = false;  // no Tick needed

	Box = CreateDefaultSubobject<UBoxComponent>(TEXT("Box"));
	RootComponent = Box;
	Box->SetBoxExtent(FVector(200.f, 200.f, 50.f));
	Box->SetCollisionProfileName(TEXT("Trigger"));  // overlaps things, doesn't block them
	Box->SetGenerateOverlapEvents(true);
	Box->ShapeColor = FColor::Red;  // red outline in the editor
}

void AKillVolume::BeginPlay()
{
	Super::BeginPlay();

	// Call our function whenever something starts overlapping the box.
	Box->OnComponentBeginOverlap.AddDynamic(this, &AKillVolume::OnBoxBeginOverlap);
}

void AKillVolume::OnBoxBeginOverlap(UPrimitiveComponent* OverlappedComp, AActor* OtherActor,
	UPrimitiveComponent* OtherComp, int32 OtherBodyIndex, bool bFromSweep,
	const FHitResult& SweepResult)
{
	// Only the server decides who dies.
	if (!HasAuthority())
	{
		return;
	}

	// Only kill pawns (characters, cars, enemies...), not random props.
	// IsValid also skips anything that is already being destroyed.
	APawn* Pawn = Cast<APawn>(OtherActor);
	if (!IsValid(Pawn))
	{
		return;
	}

	// Remember who was controlling it before it goes away.
	APlayerController* Player = Cast<APlayerController>(Pawn->GetController());

	Pawn->Destroy();

	// After a short wait, respawn the player at a Player Start.
	if (bRespawnPlayers && Player != nullptr)
	{
		TWeakObjectPtr<APlayerController> WeakPlayer = Player;  // safe if they leave the game
		FTimerHandle RespawnTimer;
		GetWorldTimerManager().SetTimer(RespawnTimer, FTimerDelegate::CreateWeakLambda(this, [WeakPlayer]()
		{
			APlayerController* PC = WeakPlayer.Get();
			AGameModeBase* GameMode = PC ? PC->GetWorld()->GetAuthGameMode() : nullptr;
			if (GameMode && PC->GetPawn() == nullptr)
			{
				GameMode->RestartPlayer(PC);
			}
		}), FMath::Max(RespawnDelay, 0.1f), false);
	}
}
