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
