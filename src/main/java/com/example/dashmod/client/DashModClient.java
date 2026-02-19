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
