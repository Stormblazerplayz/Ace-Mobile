// @title Moving Platform
// @category Unreal Engine
// @kind Unreal C++ class
// @where In Unreal Editor use Tools > New C++ Class > Actor named MovingPlatform, then replace the .h and .cpp with these two parts, build, drag it into your level and move the Target Offset diamond to set where it goes.
// @keywords unreal moving platform, ue5 c++ elevator, unreal platform back and forth, unreal lerp platform, moving part in unreal
// @about A platform that glides smoothly between its start and a target point, pausing at each end.

// ===== MovingPlatform.h =====
#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "MovingPlatform.generated.h"  // this include must stay last

class USceneComponent;
class UStaticMeshComponent;

// Change YOURGAME_API to your project's name in capitals, like MYGAME_API.
UCLASS()
class YOURGAME_API AMovingPlatform : public AActor
{
	GENERATED_BODY()

public:
	AMovingPlatform();

	virtual void Tick(float DeltaTime) override;

protected:
	virtual void BeginPlay() override;

	UPROPERTY(VisibleAnywhere, Category = "Moving Platform")
	TObjectPtr<USceneComponent> Root;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Moving Platform")
	TObjectPtr<UStaticMeshComponent> Mesh;

	// Where to go from the start. MakeEditWidget gives you a diamond to drag in the level.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Moving Platform", meta = (MakeEditWidget = true))
	FVector TargetOffset = FVector(0.f, 0.f, 300.f);

	// Seconds from one end to the other.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Moving Platform", meta = (ClampMin = "0.1"))
	float TravelTime = 3.f;

	// Seconds to wait at each end.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Moving Platform", meta = (ClampMin = "0.0"))
	float PauseTime = 1.f;

private:
	FVector StartLocation = FVector::ZeroVector;
	FVector EndLocation = FVector::ZeroVector;
	float Alpha = 0.f;         // 0 = at start, 1 = at end
	bool bGoingToEnd = true;
	float PauseLeft = 0.f;
};

// ===== MovingPlatform.cpp =====
#include "MovingPlatform.h"
#include "Components/SceneComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "UObject/ConstructorHelpers.h"

AMovingPlatform::AMovingPlatform()
{
	PrimaryActorTick.bCanEverTick = true;

	// An empty root, so squashing the mesh doesn't squash the Target Offset too.
	Root = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
	RootComponent = Root;
	Root->SetMobility(EComponentMobility::Movable);  // it has to be movable to move

	Mesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Mesh"));
	Mesh->SetupAttachment(Root);
	Mesh->SetMobility(EComponentMobility::Movable);

	// Use the built-in cube, squashed flat like a platform.
	static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeMesh(TEXT("/Engine/BasicShapes/Cube.Cube"));
	if (CubeMesh.Succeeded())
	{
		Mesh->SetStaticMesh(CubeMesh.Object);
	}
	Mesh->SetRelativeScale3D(FVector(3.f, 3.f, 0.25f));
}

void AMovingPlatform::BeginPlay()
{
	Super::BeginPlay();

	// Turn the offset (which is local to the platform) into a spot in the world.
	StartLocation = GetActorLocation();
	EndLocation = GetActorTransform().TransformPosition(TargetOffset);
}

void AMovingPlatform::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	if (PauseLeft > 0.f)  // waiting at one end
	{
		PauseLeft -= DeltaTime;
		return;
	}

	// Move Alpha toward 1 (end) or 0 (start).
	const float Step = DeltaTime / FMath::Max(TravelTime, 0.1f);
	Alpha += bGoingToEnd ? Step : -Step;

	if (Alpha >= 1.f)
	{
		Alpha = 1.f;
		bGoingToEnd = false;
		PauseLeft = PauseTime;
	}
	else if (Alpha <= 0.f)
	{
		Alpha = 0.f;
		bGoingToEnd = true;
		PauseLeft = PauseTime;
	}

	// SmoothStep makes it speed up and slow down gently instead of jerking.
	const float Smooth = FMath::SmoothStep(0.f, 1.f, Alpha);
	SetActorLocation(FMath::Lerp(StartLocation, EndLocation, Smooth));
}
