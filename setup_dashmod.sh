#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

mkdir -p src/main/java/com/example/dashmod/network
mkdir -p src/main/java/com/example/dashmod/client
mkdir -p src/main/resources/assets/dashmod/lang

cat > settings.gradle <<'SETTINGS'
pluginManagement {
    repositories {
        maven {
            name = 'Fabric'
            url = 'https://maven.fabricmc.net/'
        }
        mavenCentral()
        gradlePluginPortal()
    }
}

rootProject.name = 'mc-mod-dash'
SETTINGS

cat > gradle.properties <<'PROPS'
org.gradle.jvmargs=-Xmx2G
org.gradle.parallel=true

minecraft_version=1.21.11
yarn_mappings=1.21.11+build.1
loader_version=0.18.4
fabric_version=0.119.2+1.21.11

mod_version=1.0.0
maven_group=com.example
archives_base_name=dashmod
PROPS

cat > build.gradle <<'BUILD'
plugins {
    id 'fabric-loom' version '1.10-SNAPSHOT'
    id 'maven-publish'
}

version = project.mod_version
group = project.maven_group

base {
    archivesName = project.archives_base_name
}

repositories {
    mavenCentral()
    maven { url = 'https://maven.fabricmc.net/' }
}

dependencies {
    minecraft "com.mojang:minecraft:${project.minecraft_version}"
    mappings "net.fabricmc:yarn:${project.yarn_mappings}:v2"
    modImplementation "net.fabricmc:fabric-loader:${project.loader_version}"

    modImplementation "net.fabricmc.fabric-api:fabric-api:${project.fabric_version}"
}

loom {
    splitEnvironmentSourceSets()

    mods {
        dashmod {
            sourceSet sourceSets.main
            sourceSet sourceSets.client
        }
    }
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
    withSourcesJar()
}

tasks.withType(JavaCompile).configureEach {
    options.release = 21
}

processResources {
    inputs.property 'version', project.version

    filesMatching('fabric.mod.json') {
        expand 'version': project.version
    }
}

jar {
    from('LICENSE') {
        rename { "${it}_${project.base.archivesName.get()}" }
    }
}

publishing {
    publications {
        create('mavenJava', MavenPublication) {
            artifactId = project.archives_base_name
            from components.java
        }
    }

    repositories {
    }
}
BUILD

cat > src/main/resources/fabric.mod.json <<'MODJSON'
{
  "schemaVersion": 1,
  "id": "dashmod",
  "version": "${version}",
  "name": "Dash Mod",
  "description": "Adds a server-authoritative player dash ability.",
  "authors": [
    "Codex"
  ],
  "contact": {},
  "license": "MIT",
  "environment": "*",
  "entrypoints": {
    "main": [
      "com.example.dashmod.DashMod"
    ],
    "client": [
      "com.example.dashmod.client.DashModClient"
    ]
  },
  "mixins": [],
  "depends": {
    "fabricloader": ">=0.18.4",
    "minecraft": "~1.21.11",
    "java": ">=21",
    "fabric-api": "*"
  }
}
MODJSON

cat > src/main/resources/assets/dashmod/lang/en_us.json <<'LANG'
{
  "category.dashmod.general": "Dash Mod",
  "key.dashmod.dash": "Dash"
}
LANG

cat > src/main/java/com/example/dashmod/network/DashNetworking.java <<'NETWORK'
package com.example.dashmod.network;

import com.example.dashmod.DashMod;
import net.minecraft.network.RegistryByteBuf;
import net.minecraft.network.codec.PacketCodec;
import net.minecraft.network.packet.CustomPayload;
import net.minecraft.util.Identifier;

public final class DashNetworking {
    public static final Identifier DASH_REQUEST_ID = Identifier.of(DashMod.MOD_ID, "dash_request");
    public static final DashRequestPayload DASH_REQUEST = DashRequestPayload.INSTANCE;

    private DashNetworking() {
    }

    public record DashRequestPayload() implements CustomPayload {
        public static final DashRequestPayload INSTANCE = new DashRequestPayload();
        public static final Id<DashRequestPayload> ID = new Id<>(DASH_REQUEST_ID);
        public static final PacketCodec<RegistryByteBuf, DashRequestPayload> CODEC = PacketCodec.unit(INSTANCE);

        @Override
        public Id<? extends CustomPayload> getId() {
            return ID;
        }
    }
}
NETWORK

cat > src/main/java/com/example/dashmod/DashMod.java <<'MODINIT'
package com.example.dashmod;

import com.example.dashmod.network.DashNetworking;
import net.fabricmc.api.ModInitializer;
import net.fabricmc.fabric.api.networking.v1.PayloadTypeRegistry;
import net.fabricmc.fabric.api.networking.v1.ServerPlayNetworking;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DashMod implements ModInitializer {
    public static final String MOD_ID = "dashmod";
    public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);

    @Override
    public void onInitialize() {
        PayloadTypeRegistry.playC2S().register(DashNetworking.DashRequestPayload.ID, DashNetworking.DashRequestPayload.CODEC);

        ServerPlayNetworking.registerGlobalReceiver(DashNetworking.DashRequestPayload.ID, (payload, context) ->
                context.server().execute(() -> DashServerLogic.tryDash(context.player()))
        );

        LOGGER.info("Initialized {}", MOD_ID);
    }
}
MODINIT

cat > src/main/java/com/example/dashmod/DashServerLogic.java <<'SERVER'
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
SERVER

cat > src/main/java/com/example/dashmod/client/DashModClient.java <<'CLIENT'
package com.example.dashmod.client;

import com.example.dashmod.network.DashNetworking;
import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import net.fabricmc.fabric.api.client.keybinding.v1.KeyBindingHelper;
import net.fabricmc.fabric.api.client.networking.v1.ClientPlayNetworking;
import net.minecraft.client.option.KeyBinding;
import net.minecraft.client.util.InputUtil;
import org.lwjgl.glfw.GLFW;

public class DashModClient implements ClientModInitializer {
    private static final String KEY_CATEGORY = "category.dashmod.general";
    private static final String KEY_TRANSLATION = "key.dashmod.dash";

    private static KeyBinding dashKey;

    @Override
    public void onInitializeClient() {
        dashKey = KeyBindingHelper.registerKeyBinding(new KeyBinding(
                KEY_TRANSLATION,
                InputUtil.Type.KEYSYM,
                GLFW.GLFW_KEY_R,
                KEY_CATEGORY
        ));

        ClientTickEvents.END_CLIENT_TICK.register(client -> {
            while (dashKey.wasPressed()) {
                if (client.player == null || client.getNetworkHandler() == null) {
                    continue;
                }

                ClientPlayNetworking.send(DashNetworking.DASH_REQUEST);
            }
        });
    }
}
CLIENT

cat > .gitignore <<'GITIGNORE'
.gradle/
build/
out/
*.iml
.idea/
GITIGNORE

cat > LICENSE <<'LICENSE'
MIT License

Copyright (c) 2026

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
LICENSE

cat > README.md <<'README'
# Dash Mod (Fabric 1.21.11)

## Bootstrap this project
Run from any folder:

```bash
bash setup_dashmod.sh my-dash-mod
cd my-dash-mod
```

## Add Gradle wrapper (if missing)
If `./gradlew` is not present, generate it with a local Gradle install:

```bash
gradle wrapper
```

## Run and build

```bash
./gradlew runClient
./gradlew build
```
README

echo "Project files written to: $(pwd)"
