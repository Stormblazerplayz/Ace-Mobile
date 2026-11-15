// @title Health Component for Any Actor
// @category Unreal Engine
// @kind Unreal C++ class
// @where In Unreal Editor use Tools > New C++ Class > Actor Component named HealthComponent, replace the .h and .cpp with these two parts, build, then click Add on any actor and pick Health.
// @keywords unreal health component, ue5 c++ take damage, unreal actor component hp, unreal on died event, heal in unreal
// @about A component you can add to any actor to give it health, take damage, heal, and fire an event when it dies.

// ===== HealthComponent.h =====
#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "HealthComponent.generated.h"  // this include must stay last

class AController;
class UDamageType;

// Events Blueprints can listen to, like "when health changes" and "when it dies".
DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FOnHealthChanged, float, NewHealth, float, Change);
DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnDied);

// Change YOURGAME_API to your project's name in capitals, like MYGAME_API.
UCLASS(ClassGroup = (Custom), meta = (BlueprintSpawnableComponent))
class YOURGAME_API UHealthComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	UHealthComponent();

	UFUNCTION(BlueprintCallable, Category = "Health")
	void Heal(float Amount);

	UFUNCTION(BlueprintPure, Category = "Health")
	float GetHealth() const { return Health; }

	UFUNCTION(BlueprintPure, Category = "Health")
	bool IsDead() const { return Health <= 0.f; }

	UPROPERTY(BlueprintAssignable, Category = "Health")
	FOnHealthChanged OnHealthChanged;

	UPROPERTY(BlueprintAssignable, Category = "Health")
	FOnDied OnDied;

protected:
	virtual void BeginPlay() override;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Health", meta = (ClampMin = "1"))
	float MaxHealth = 100.f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Health")
	float Health = 0.f;

	// Unreal calls this whenever something uses ApplyDamage on our owner.
	UFUNCTION()
	void HandleTakeAnyDamage(AActor* DamagedActor, float Damage, const UDamageType* DamageType,
		AController* InstigatedBy, AActor* DamageCauser);
};

// ===== HealthComponent.cpp =====
#include "HealthComponent.h"
#include "GameFramework/Actor.h"

UHealthComponent::UHealthComponent()
{
	PrimaryComponentTick.bCanEverTick = false;  // health doesn't need to update every frame
}

void UHealthComponent::BeginPlay()
{
	Super::BeginPlay();
	Health = MaxHealth;

	// Listen for damage sent to the actor we are attached to.
	if (AActor* OwnerActor = GetOwner())
	{
		OwnerActor->OnTakeAnyDamage.AddDynamic(this, &UHealthComponent::HandleTakeAnyDamage);
	}
}

void UHealthComponent::HandleTakeAnyDamage(AActor* DamagedActor, float Damage, const UDamageType* DamageType,
	AController* InstigatedBy, AActor* DamageCauser)
{
	if (Damage <= 0.f || IsDead())
	{
		return;
	}

	const float Old = Health;
	Health = FMath::Clamp(Health - Damage, 0.f, MaxHealth);
	OnHealthChanged.Broadcast(Health, Health - Old);

	UE_LOG(LogTemp, Log, TEXT("%s took %.0f damage, health now %.0f"), *GetOwner()->GetName(), Damage, Health);

	if (IsDead())
	{
		OnDied.Broadcast();  // a Blueprint can play an animation, then destroy the actor
	}
}

void UHealthComponent::Heal(float Amount)
{
	if (Amount <= 0.f || IsDead())
	{
		return;  // can't heal the dead!
	}
	const float Old = Health;
	Health = FMath::Min(Health + Amount, MaxHealth);
	OnHealthChanged.Broadcast(Health, Health - Old);
}
