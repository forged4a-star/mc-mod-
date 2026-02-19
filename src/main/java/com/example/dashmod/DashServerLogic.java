package com.example.dashmod;

import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.sound.SoundCategory;
import net.minecraft.sound.SoundEvents;
import net.minecraft.util.math.Vec3d;
import net.minecraft.world.World;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

public final class DashServerLogic {
    private static final Map<UUID, Long> LAST_DASH_TICK = new ConcurrentHashMap<>();

    public static final int DASH_COOLDOWN_TICKS = 40;
    public static final double DASH_STRENGTH = 1.35D;
    public static final double DASH_UPWARD_NUDGE = 0.08D;

    private DashServerLogic() {
    }

    public static void tryDash(PlayerEntity player) {
        if (!isValidDasher(player)) {
            return;
        }

        World world = player.getWorld();
        long currentTick = world.getTime();
        UUID uuid = player.getUuid();
        long nextAllowedTick = LAST_DASH_TICK.getOrDefault(uuid, Long.MIN_VALUE) + DASH_COOLDOWN_TICKS;
        if (currentTick < nextAllowedTick) {
            return;
        }

        Vec3d look = player.getRotationVector();
        Vec3d flatDirection = new Vec3d(look.x, 0.0D, look.z);
        if (flatDirection.lengthSquared() < 1.0E-6D) {
            return;
        }

        Vec3d impulse = flatDirection.normalize().multiply(DASH_STRENGTH).add(0.0D, DASH_UPWARD_NUDGE, 0.0D);
        Vec3d updatedVelocity = player.getVelocity().add(impulse);
        player.setVelocity(updatedVelocity);
        player.velocityModified = true;

        LAST_DASH_TICK.put(uuid, currentTick);

        // Verified-safe fallback sound. Swap to the exact wind-burst SoundEvent for your mappings/version if available.
        world.playSound(
                null,
                player.getX(),
                player.getY(),
                player.getZ(),
                SoundEvents.ENTITY_PLAYER_ATTACK_SWEEP,
                SoundCategory.PLAYERS,
                0.9F,
                1.2F
        );
    }

    private static boolean isValidDasher(PlayerEntity player) {
        return player.isAlive()
                && !player.isSpectator()
                && !player.isSleeping()
                && !player.isInsideWall();
    }
}
