// @title Rotating Actor
// @category Unreal Engine
// @kind Unreal C++ class
// @where In Unreal Editor use Tools > New C++ Class > Actor named RotatingActor, then replace the .h and .cpp with these two parts, build, and drag it into your level.
// @keywords unreal rotating actor, unreal spinning object, ue5 c++ rotate every tick, spin a cube in unreal
// @about An actor with a cube mesh that spins a little bit every frame.

// ===== RotatingActor.h =====
#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "RotatingActor.generated.h"  // this include must stay last

class UStaticMeshComponent;

// Change YOURGAME_API to your project's name in capitals, like MYGAME_API.
UCLASS()
class YOURGAME_API ARotatingActor : public AActor
{
	GENERATED_BODY()

public:
	ARotatingActor();

	virtual void Tick(float DeltaTime) override;

protected:
	// The thing you see. Pick any mesh in the Details panel.
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Rotating")
	TObjectPtr<UStaticMeshComponent> Mesh;

	// How fast to spin, in degrees per second (Yaw spins like a top).
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Rotating")
	FRotator RotationSpeed = FRotator(0.f, 90.f, 0.f);
};

// ===== RotatingActor.cpp =====
#include "RotatingActor.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "UObject/ConstructorHelpers.h"

ARotatingActor::ARotatingActor()
{
	// Let Tick run every frame.
	PrimaryActorTick.bCanEverTick = true;

	Mesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Mesh"));
	RootComponent = Mesh;
	Mesh->SetMobility(EComponentMobility::Movable);  // it has to be movable to spin

	// Start with Unreal's built-in cube so you can see it right away.
	static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeMesh(TEXT("/Engine/BasicShapes/Cube.Cube"));
	if (CubeMesh.Succeeded())
	{
		Mesh->SetStaticMesh(CubeMesh.Object);
	}
}

void ARotatingActor::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	// DeltaTime is the seconds since last frame, so the speed is the same on fast and slow PCs.
	AddActorLocalRotation(RotationSpeed * DeltaTime);
}
