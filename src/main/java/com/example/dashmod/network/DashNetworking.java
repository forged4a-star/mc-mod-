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
