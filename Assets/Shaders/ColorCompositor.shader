Shader "Custom/ColorCompositor"
{
    Properties
    {
        _GrayTex ("Grayscale", 2D) = "black" {}
        _ColorTex ("Color", 2D) = "black" {}
        _MaskTex ("Mask", 2D) = "black" {}

        _BlurSize ("Mask Blur Size", Range(0, 10)) = 2
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Transparent"
        }

        Cull Off
        ZWrite Off
        ZTest Always

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_GrayTex);
            SAMPLER(sampler_GrayTex);

            TEXTURE2D(_ColorTex);
            SAMPLER(sampler_ColorTex);

            TEXTURE2D(_MaskTex);
            SAMPLER(sampler_MaskTex);

            float4 _MaskTex_TexelSize;
            float _BlurSize;


            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };


            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };


            Varyings vert(Attributes input)
            {
                Varyings output;

                output.positionHCS =
                    TransformObjectToHClip(input.positionOS.xyz);

                output.uv = input.uv;

                return output;
            }


            half SampleMask(float2 uv)
            {
                return SAMPLE_TEXTURE2D(
                    _MaskTex,
                    sampler_MaskTex,
                    uv
                ).r;
            }


            half BlurMask(float2 uv)
            {
                float2 texel = _MaskTex_TexelSize.xy * _BlurSize;

                half mask = 0;

                // Center
                mask += SampleMask(uv) * 0.227027;

                // Horizontal
                mask += SampleMask(uv + float2(texel.x, 0)) * 0.194595;
                mask += SampleMask(uv - float2(texel.x, 0)) * 0.194595;

                mask += SampleMask(uv + float2(texel.x * 2, 0)) * 0.121622;
                mask += SampleMask(uv - float2(texel.x * 2, 0)) * 0.121622;

                mask += SampleMask(uv + float2(texel.x * 3, 0)) * 0.054054;
                mask += SampleMask(uv - float2(texel.x * 3, 0)) * 0.054054;

                mask += SampleMask(uv + float2(texel.x * 4, 0)) * 0.016216;
                mask += SampleMask(uv - float2(texel.x * 4, 0)) * 0.016216;


                // Vertical
                mask += SampleMask(uv + float2(0, texel.y)) * 0.194595;
                mask += SampleMask(uv - float2(0, texel.y)) * 0.194595;

                mask += SampleMask(uv + float2(0, texel.y * 2)) * 0.121622;
                mask += SampleMask(uv - float2(0, texel.y * 2)) * 0.121622;

                mask += SampleMask(uv + float2(0, texel.y * 3)) * 0.054054;
                mask += SampleMask(uv - float2(0, texel.y * 3)) * 0.054054;

                mask += SampleMask(uv + float2(0, texel.y * 4)) * 0.016216;
                mask += SampleMask(uv - float2(0, texel.y * 4)) * 0.016216;

                return saturate(mask);
            }


            half4 frag(Varyings input) : SV_Target
            {
                half4 gray = SAMPLE_TEXTURE2D(
                    _GrayTex,
                    sampler_GrayTex,
                    input.uv
                );

                half4 color = SAMPLE_TEXTURE2D(
                    _ColorTex,
                    sampler_ColorTex,
                    input.uv
                );

                half mask = BlurMask(input.uv);

                return lerp(gray, color, mask);
            }

            ENDHLSL
        }
    }
}