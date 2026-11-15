// @title Motion Sensor Light
// @category Unreal Engine
// @kind Unreal C++ class
// @where In Unreal Editor use Tools > New C++ Class > Actor named TriggerLight, replace the .h and .cpp with these two parts, build, and drag one into a dark room.
// @keywords unreal trigger light, ue5 c++ point light switch, unreal light turns on when player near, unreal settimer delay, motion sensor light unreal
// @about A light that switches on when the player walks into its area and switches off a few seconds after they leave.

// ===== TriggerLight.h =====
#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "TriggerLight.generated.h"  // this include must stay last

class UPointLightComponent;
class UPrimitiveComponent;
class USphereComponent;

// Change YOURGAME_API to your project's name in capitals, like MYGAME_API.
UCLASS()
class YOURGAME_API ATriggerLight : public AActor
{
	GENERATED_BODY()

public:
	ATriggerLight();

protected:
	virtual void BeginPlay() override;

	UPROPERTY(VisibleAnywhere, Category = "Light")
	TObjectPtr<USphereComponent> Sensor;

	UPROPERTY(VisibleAnywhere, Category = "Light")
	TObjectPtr<UPointLightComponent> Light;

	// Seconds the light stays on after the player leaves.
	UPROPERTY(EditAnywhere, Category = "Light", meta = (ClampMin = "0"))
	float StayOnTime = 3.f;

	UFUNCTION()
	void OnEnter(UPrimitiveComponent* OverlappedComp, AActor* OtherActor, UPrimitiveComponent* OtherComp,
		int32 OtherBodyIndex, bool bFromSweep, const FHitResult& SweepResult);

	UFUNCTION()
	void OnLeave(UPrimitiveComponent* OverlappedComp, AActor* OtherActor, UPrimitiveComponent* OtherComp,
		int32 OtherBodyIndex);

	void TurnOff();

private:
	FTimerHandle OffTimer;
};

// ===== TriggerLight.cpp =====
#include "TriggerLight.h"
#include "Components/PointLightComponent.h"
#include "Components/SphereComponent.h"
#include "GameFramework/Pawn.h"
#include "TimerManager.h"

ATriggerLight::ATriggerLight()
{
	PrimaryActorTick.bCanEverTick = false;

	Sensor = CreateDefaultSubobject<USphereComponent>(TEXT("Sensor"));
	Sensor->SetSphereRadius(400.f);
	Sensor->SetCollisionProfileName(TEXT("Trigger"));
	RootComponent = Sensor;

	Light = CreateDefaultSubobject<UPointLightComponent>(TEXT("Light"));
	Light->SetupAttachment(Sensor);
	Light->SetRelativeLocation(FVector(0.f, 0.f, 200.f));
	Light->SetIntensity(5000.f);
	Light->SetLightColor(FLinearColor(1.f, 0.9f, 0.7f));  // warm white
	Light->SetVisibility(false);  // start switched off
}

void ATriggerLight::BeginPlay()
{
	Super::BeginPlay();
	Sensor->OnComponentBeginOverlap.AddDynamic(this, &ATriggerLight::OnEnter);
	Sensor->OnComponentEndOverlap.AddDynamic(this, &ATriggerLight::OnLeave);
}

void ATriggerLight::OnEnter(UPrimitiveComponent* OverlappedComp, AActor* OtherActor, UPrimitiveComponent* OtherComp,
	int32 OtherBodyIndex, bool bFromSweep, const FHitResult& SweepResult)
{
	APawn* Pawn = Cast<APawn>(OtherActor);
	if (Pawn && Pawn->IsPlayerControlled())
	{
		GetWorldTimerManager().ClearTimer(OffTimer);  // cancel a switch-off that was waiting
		Light->SetVisibility(true);
	}
}

void ATriggerLight::OnLeave(UPrimitiveComponent* OverlappedComp, AActor* OtherActor, UPrimitiveComponent* OtherComp,
	int32 OtherBodyIndex)
{
	APawn* Pawn = Cast<APawn>(OtherActor);
	if (Pawn && Pawn->IsPlayerControlled())
	{
		// Wait a few seconds, then call TurnOff once (false means don't repeat).
		GetWorldTimerManager().SetTimer(OffTimer, this, &ATriggerLight::TurnOff, FMath::Max(StayOnTime, 0.01f), false);
	}
}

void ATriggerLight::TurnOff()
{
	Light->SetVisibility(false);
}
