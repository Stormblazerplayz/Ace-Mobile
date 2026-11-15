// @title Spinning Coin Pickup
// @category Unreal Engine
// @kind Unreal C++ class
// @where In Unreal Editor use Tools > New C++ Class > Actor named CoinPickup, then replace the .h and .cpp with these two parts, build, and drag some into your level.
// @keywords unreal coin pickup, unreal collectible, ue5 c++ collect coins, unreal pickup item
// @about A spinning coin that disappears and shows a message on screen when the player touches it.

// ===== CoinPickup.h =====
#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "CoinPickup.generated.h"  // this include must stay last

class UPrimitiveComponent;
class USphereComponent;
class UStaticMeshComponent;

// Change YOURGAME_API to your project's name in capitals, like MYGAME_API.
UCLASS()
class YOURGAME_API ACoinPickup : public AActor
{
	GENERATED_BODY()

public:
	ACoinPickup();

	virtual void Tick(float DeltaTime) override;

protected:
	virtual void BeginPlay() override;

	// The invisible ball that notices the player.
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Coin")
	TObjectPtr<USphereComponent> Sphere;

	// The coin you see.
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Coin")
	TObjectPtr<UStaticMeshComponent> Mesh;

	// How many points this coin is worth.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Coin")
	int32 Value = 1;

	// Spin speed in degrees per second.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Coin")
	float SpinSpeed = 180.f;

	UFUNCTION()
	void OnSphereBeginOverlap(UPrimitiveComponent* OverlappedComp, AActor* OtherActor,
		UPrimitiveComponent* OtherComp, int32 OtherBodyIndex, bool bFromSweep,
		const FHitResult& SweepResult);
};

// ===== CoinPickup.cpp =====
#include "CoinPickup.h"
#include "Components/SphereComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/Engine.h"
#include "Engine/StaticMesh.h"
#include "GameFramework/Pawn.h"
#include "UObject/ConstructorHelpers.h"

ACoinPickup::ACoinPickup()
{
	PrimaryActorTick.bCanEverTick = true;

	Sphere = CreateDefaultSubobject<USphereComponent>(TEXT("Sphere"));
	RootComponent = Sphere;
	Sphere->SetSphereRadius(60.f);
	Sphere->SetCollisionProfileName(TEXT("Trigger"));
	Sphere->SetGenerateOverlapEvents(true);

	// A thin cylinder standing on its edge looks like a coin.
	Mesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Mesh"));
	Mesh->SetupAttachment(Sphere);
	Mesh->SetMobility(EComponentMobility::Movable);  // so it can spin
	static ConstructorHelpers::FObjectFinder<UStaticMesh> CylinderMesh(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
	if (CylinderMesh.Succeeded())
	{
		Mesh->SetStaticMesh(CylinderMesh.Object);
	}
	Mesh->SetRelativeRotation(FRotator(90.f, 0.f, 0.f));
	Mesh->SetRelativeScale3D(FVector(0.6f, 0.6f, 0.1f));
	Mesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);  // the sphere handles touching
}

void ACoinPickup::BeginPlay()
{
	Super::BeginPlay();
	Sphere->OnComponentBeginOverlap.AddDynamic(this, &ACoinPickup::OnSphereBeginOverlap);
}

void ACoinPickup::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);
	AddActorLocalRotation(FRotator(0.f, SpinSpeed * DeltaTime, 0.f));
}

void ACoinPickup::OnSphereBeginOverlap(UPrimitiveComponent* OverlappedComp, AActor* OtherActor,
	UPrimitiveComponent* OtherComp, int32 OtherBodyIndex, bool bFromSweep,
	const FHitResult& SweepResult)
{
	// Only the player can collect coins, not enemies.
	APawn* Pawn = Cast<APawn>(OtherActor);
	if (!IsValid(Pawn) || !Pawn->IsPlayerControlled())
	{
		return;
	}

	// Show a message on the screen for 2 seconds.
	if (GEngine)
	{
		GEngine->AddOnScreenDebugMessage(-1, 2.f, FColor::Yellow,
			FString::Printf(TEXT("Coin collected! +%d"), Value));
	}

	Destroy();  // the coin disappears
}
