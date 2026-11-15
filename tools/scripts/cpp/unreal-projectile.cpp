// @title Projectile That Deals Damage
// @category Unreal Engine
// @kind Unreal C++ class
// @where In Unreal Editor use Tools > New C++ Class > Actor named SimpleProjectile, replace the .h and .cpp with these two parts, build, then spawn it from your character's fire button.
// @keywords unreal projectile, ue5 c++ bullet, unreal projectile movement component, unreal apply damage on hit, shoot a ball in unreal
// @about A ball projectile that flies forward in a gentle arc and damages whatever it hits before disappearing.

// ===== SimpleProjectile.h =====
#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "SimpleProjectile.generated.h"  // this include must stay last

class UPrimitiveComponent;
class UProjectileMovementComponent;
class USphereComponent;
class UStaticMeshComponent;

// Change YOURGAME_API to your project's name in capitals, like MYGAME_API.
UCLASS()
class YOURGAME_API ASimpleProjectile : public AActor
{
	GENERATED_BODY()

public:
	ASimpleProjectile();

protected:
	virtual void BeginPlay() override;

	UPROPERTY(VisibleAnywhere, Category = "Projectile")
	TObjectPtr<USphereComponent> Collision;

	UPROPERTY(VisibleAnywhere, Category = "Projectile")
	TObjectPtr<UStaticMeshComponent> Mesh;

	// Unreal's built-in mover for bullets, arrows and balls.
	UPROPERTY(VisibleAnywhere, Category = "Projectile")
	TObjectPtr<UProjectileMovementComponent> Movement;

	UPROPERTY(EditAnywhere, Category = "Projectile")
	float Damage = 20.f;

	UFUNCTION()
	void OnHit(UPrimitiveComponent* HitComp, AActor* OtherActor, UPrimitiveComponent* OtherComp,
		FVector NormalImpulse, const FHitResult& Hit);
};

// ===== SimpleProjectile.cpp =====
#include "SimpleProjectile.h"
#include "Components/SphereComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "GameFramework/DamageType.h"
#include "GameFramework/Pawn.h"
#include "GameFramework/ProjectileMovementComponent.h"
#include "Kismet/GameplayStatics.h"
#include "UObject/ConstructorHelpers.h"

ASimpleProjectile::ASimpleProjectile()
{
	PrimaryActorTick.bCanEverTick = false;

	Collision = CreateDefaultSubobject<USphereComponent>(TEXT("Collision"));
	Collision->SetSphereRadius(10.f);
	Collision->SetCollisionProfileName(TEXT("BlockAllDynamic"));
	RootComponent = Collision;

	Mesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Mesh"));
	Mesh->SetupAttachment(Collision);
	static ConstructorHelpers::FObjectFinder<UStaticMesh> Ball(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
	if (Ball.Succeeded())
	{
		Mesh->SetStaticMesh(Ball.Object);
	}
	Mesh->SetRelativeScale3D(FVector(0.2f));  // the basic sphere is 100 wide, so this is 20 wide
	Mesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);

	Movement = CreateDefaultSubobject<UProjectileMovementComponent>(TEXT("Movement"));
	Movement->UpdatedComponent = Collision;
	Movement->InitialSpeed = 2000.f;
	Movement->MaxSpeed = 2000.f;
	Movement->bRotationFollowsVelocity = true;
	Movement->bShouldBounce = false;
	Movement->ProjectileGravityScale = 0.3f;  // a gentle arc

	InitialLifeSpan = 3.f;  // destroy itself after 3 seconds if it hits nothing
}

void ASimpleProjectile::BeginPlay()
{
	Super::BeginPlay();
	Collision->OnComponentHit.AddDynamic(this, &ASimpleProjectile::OnHit);

	// Don't hit the character who fired it. Set Instigator when you spawn the projectile.
	if (APawn* Shooter = GetInstigator())
	{
		Collision->IgnoreActorWhenMoving(Shooter, true);
	}
}

void ASimpleProjectile::OnHit(UPrimitiveComponent* HitComp, AActor* OtherActor, UPrimitiveComponent* OtherComp,
	FVector NormalImpulse, const FHitResult& Hit)
{
	if (OtherActor && OtherActor != this)
	{
		// Things with a HealthComponent (or their own damage code) will feel this.
		UGameplayStatics::ApplyDamage(OtherActor, Damage, GetInstigatorController(), this, UDamageType::StaticClass());
	}
	Destroy();
}
