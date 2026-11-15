// @title Automatic Sliding Door
// @category Unreal Engine
// @kind Unreal C++ class
// @where In Unreal Editor use Tools > New C++ Class > Actor named SlidingDoor, replace the .h and .cpp with these two parts, build, and drag one into a doorway.
// @keywords unreal sliding door, ue5 c++ automatic door, unreal door opens when near, unreal trigger box overlap, unreal vinterp door
// @about A sci-fi door that slides open smoothly when the player walks up to it and closes again after they leave.

// ===== SlidingDoor.h =====
#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "SlidingDoor.generated.h"  // this include must stay last

class UBoxComponent;
class UPrimitiveComponent;
class UStaticMeshComponent;

// Change YOURGAME_API to your project's name in capitals, like MYGAME_API.
UCLASS()
class YOURGAME_API ASlidingDoor : public AActor
{
	GENERATED_BODY()

public:
	ASlidingDoor();

	virtual void Tick(float DeltaTime) override;

protected:
	virtual void BeginPlay() override;

	UPROPERTY(VisibleAnywhere, Category = "Door")
	TObjectPtr<USceneComponent> Root;

	// The door panel you see.
	UPROPERTY(VisibleAnywhere, Category = "Door")
	TObjectPtr<UStaticMeshComponent> Door;

	// The invisible area in front of and behind the door.
	UPROPERTY(VisibleAnywhere, Category = "Door")
	TObjectPtr<UBoxComponent> Trigger;

	// How far the door slides, sideways, when open.
	UPROPERTY(EditAnywhere, Category = "Door")
	FVector OpenOffset = FVector(0.f, 200.f, 0.f);

	// Speed in units per second.
	UPROPERTY(EditAnywhere, Category = "Door")
	float Speed = 300.f;

	UFUNCTION()
	void OnEnter(UPrimitiveComponent* OverlappedComp, AActor* OtherActor, UPrimitiveComponent* OtherComp,
		int32 OtherBodyIndex, bool bFromSweep, const FHitResult& SweepResult);

	UFUNCTION()
	void OnLeave(UPrimitiveComponent* OverlappedComp, AActor* OtherActor, UPrimitiveComponent* OtherComp,
		int32 OtherBodyIndex);

private:
	FVector ClosedSpot;
	int32 PeopleInside = 0;  // counts pawns, so two players don't confuse the door
};

// ===== SlidingDoor.cpp =====
#include "SlidingDoor.h"
#include "Components/BoxComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "GameFramework/Pawn.h"
#include "UObject/ConstructorHelpers.h"

ASlidingDoor::ASlidingDoor()
{
	PrimaryActorTick.bCanEverTick = true;

	Root = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
	RootComponent = Root;

	// A cube squashed flat makes a door 20 wide, 200 across and 300 tall.
	Door = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Door"));
	Door->SetupAttachment(Root);
	Door->SetMobility(EComponentMobility::Movable);
	static ConstructorHelpers::FObjectFinder<UStaticMesh> Cube(TEXT("/Engine/BasicShapes/Cube.Cube"));
	if (Cube.Succeeded())
	{
		Door->SetStaticMesh(Cube.Object);
	}
	Door->SetRelativeScale3D(FVector(0.2f, 2.f, 3.f));
	Door->SetRelativeLocation(FVector(0.f, 0.f, 150.f));

	Trigger = CreateDefaultSubobject<UBoxComponent>(TEXT("Trigger"));
	Trigger->SetupAttachment(Root);
	Trigger->SetBoxExtent(FVector(250.f, 150.f, 150.f));
	Trigger->SetRelativeLocation(FVector(0.f, 0.f, 150.f));
	Trigger->SetCollisionProfileName(TEXT("Trigger"));
}

void ASlidingDoor::BeginPlay()
{
	Super::BeginPlay();
	ClosedSpot = Door->GetRelativeLocation();
	Trigger->OnComponentBeginOverlap.AddDynamic(this, &ASlidingDoor::OnEnter);
	Trigger->OnComponentEndOverlap.AddDynamic(this, &ASlidingDoor::OnLeave);
}

void ASlidingDoor::OnEnter(UPrimitiveComponent* OverlappedComp, AActor* OtherActor, UPrimitiveComponent* OtherComp,
	int32 OtherBodyIndex, bool bFromSweep, const FHitResult& SweepResult)
{
	if (Cast<APawn>(OtherActor))
	{
		PeopleInside++;
	}
}

void ASlidingDoor::OnLeave(UPrimitiveComponent* OverlappedComp, AActor* OtherActor, UPrimitiveComponent* OtherComp,
	int32 OtherBodyIndex)
{
	if (Cast<APawn>(OtherActor))
	{
		PeopleInside = FMath::Max(0, PeopleInside - 1);
	}
}

void ASlidingDoor::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	// Slide a little toward the open or closed spot each frame, at a steady speed.
	const FVector Target = PeopleInside > 0 ? ClosedSpot + OpenOffset : ClosedSpot;
	const FVector Now = Door->GetRelativeLocation();
	Door->SetRelativeLocation(FMath::VInterpConstantTo(Now, Target, DeltaTime, Speed));
}
