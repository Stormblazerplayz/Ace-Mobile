// @title Launch Pad (Jump Pad)
// @category Unreal Engine
// @kind Unreal C++ class
// @where In Unreal Editor use Tools > New C++ Class > Actor named LaunchPad, then replace the .h and .cpp with these two parts, build, and drag it into your level.
// @keywords unreal launch pad, unreal jump pad, ue5 c++ bounce pad, launch character in unreal
// @about A pad that throws any character who steps on it high into the air.

// ===== LaunchPad.h =====
#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "LaunchPad.generated.h"  // this include must stay last

class UBoxComponent;
class UPrimitiveComponent;
class USceneComponent;
class UStaticMeshComponent;

// Change YOURGAME_API to your project's name in capitals, like MYGAME_API.
UCLASS()
class YOURGAME_API ALaunchPad : public AActor
{
	GENERATED_BODY()

public:
	ALaunchPad();

protected:
	virtual void BeginPlay() override;

	UPROPERTY(VisibleAnywhere, Category = "Launch Pad")
	TObjectPtr<USceneComponent> Root;

	// The flat pad you see and stand on.
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Launch Pad")
	TObjectPtr<UStaticMeshComponent> Pad;

	// The invisible box just above the pad that notices characters.
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Launch Pad")
	TObjectPtr<UBoxComponent> Trigger;

	// How hard to launch: Z is up, X is forward (the pad's forward).
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Launch Pad")
	FVector LaunchVelocity = FVector(0.f, 0.f, 1500.f);

	UFUNCTION()
	void OnTriggerBeginOverlap(UPrimitiveComponent* OverlappedComp, AActor* OtherActor,
		UPrimitiveComponent* OtherComp, int32 OtherBodyIndex, bool bFromSweep,
		const FHitResult& SweepResult);
};

// ===== LaunchPad.cpp =====
#include "LaunchPad.h"
#include "Components/BoxComponent.h"
#include "Components/SceneComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "GameFramework/Character.h"
#include "UObject/ConstructorHelpers.h"

ALaunchPad::ALaunchPad()
{
	PrimaryActorTick.bCanEverTick = false;

	Root = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
	RootComponent = Root;

	// A flat cylinder for the pad (100 wide x 100 tall, squashed to 150 x 10).
	Pad = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Pad"));
	Pad->SetupAttachment(Root);
	static ConstructorHelpers::FObjectFinder<UStaticMesh> CylinderMesh(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
	if (CylinderMesh.Succeeded())
	{
		Pad->SetStaticMesh(CylinderMesh.Object);
	}
	Pad->SetRelativeScale3D(FVector(1.5f, 1.5f, 0.1f));

	// The trigger box sits on top of the pad.
	Trigger = CreateDefaultSubobject<UBoxComponent>(TEXT("Trigger"));
	Trigger->SetupAttachment(Root);
	Trigger->SetRelativeLocation(FVector(0.f, 0.f, 50.f));
	Trigger->SetBoxExtent(FVector(75.f, 75.f, 50.f));
	Trigger->SetCollisionProfileName(TEXT("Trigger"));
	Trigger->SetGenerateOverlapEvents(true);
}

void ALaunchPad::BeginPlay()
{
	Super::BeginPlay();
	Trigger->OnComponentBeginOverlap.AddDynamic(this, &ALaunchPad::OnTriggerBeginOverlap);
}

void ALaunchPad::OnTriggerBeginOverlap(UPrimitiveComponent* OverlappedComp, AActor* OtherActor,
	UPrimitiveComponent* OtherComp, int32 OtherBodyIndex, bool bFromSweep,
	const FHitResult& SweepResult)
{
	// Only characters can be launched (they have LaunchCharacter).
	ACharacter* Character = Cast<ACharacter>(OtherActor);
	if (!IsValid(Character))
	{
		return;
	}

	// Turn the launch direction so "forward" follows the way the pad faces.
	const FVector WorldVelocity = GetActorRotation().RotateVector(LaunchVelocity);

	// true, true = replace the character's current speed instead of adding to it.
	Character->LaunchCharacter(WorldVelocity, true, true);
}
