
using System.Collections;
using System.Collections.Generic;
using System.Threading;
using UnityEngine;
using UnityEngine.Rendering;

public class ShaderToyBuffer : MonoBehaviour
{
    public Material material = null;
    public Material bufferMaterial = null;
    public Material bufferBMaterial = null;
    public Material bufferCMaterial = null;
    public Material bufferDMaterial = null;
    private CommandBuffer _commandBuffer = null;
    public Texture _bufferA = null;
    public Texture _bufferB = null;
    public Texture _bufferC = null;
    public Texture _bufferD = null;
    public Texture _tempRenderTexture = null;

    public Texture bufferAChannel0 = null;
    public Texture bufferAChannel1 = null;
    public Texture bufferAChannel2 = null;
    public Texture bufferAChannel3 = null;

    public Texture bufferBChannel0 = null;
    public Texture bufferBChannel1 = null;
    public Texture bufferBChannel2 = null;
    public Texture bufferBChannel3 = null;

    public Texture bufferCChannel0 = null;
    public Texture bufferCChannel1 = null;
    public Texture bufferCChannel2 = null;
    public Texture bufferCChannel3 = null;

    public Texture bufferDChannel0 = null;
    public Texture bufferDChannel1 = null;
    public Texture bufferDChannel2 = null;
    public Texture bufferDChannel3 = null;

    public Texture channel0 = null;
    public Texture channel1 = null;
    public Texture channel2 = null;
    public Texture channel3 = null;

    private int iChannel0Id = Shader.PropertyToID("iChannel0");
    private int iChannel1Id = Shader.PropertyToID("iChannel1");
    private int iChannel2Id = Shader.PropertyToID("iChannel2");
    private int iChannel3Id = Shader.PropertyToID("iChannel3");

    private int iFrame = 0;

    void Start()
    {
        iFrame = 0;
    }

    private void OnEnable()
    {
        iFrame = 0;
        ClearBuffer();
        if (bufferMaterial != null && _commandBuffer == null && Camera.main != null)
        {
            _commandBuffer = new CommandBuffer { name = "ShaderToyBuffer" };
            _commandBuffer.SetGlobalTexture(iChannel0Id, bufferAChannel0);
            _commandBuffer.SetGlobalTexture(iChannel1Id, bufferAChannel1);
            _commandBuffer.SetGlobalTexture(iChannel2Id, bufferAChannel2);
            _commandBuffer.SetGlobalTexture(iChannel3Id, bufferAChannel3);
            _commandBuffer.Blit(_bufferA, _tempRenderTexture, bufferMaterial);
            _commandBuffer.Blit(_tempRenderTexture, _bufferA);

            _commandBuffer.SetGlobalTexture(iChannel0Id, bufferBChannel0);
            _commandBuffer.SetGlobalTexture(iChannel1Id, bufferBChannel1);
            _commandBuffer.SetGlobalTexture(iChannel2Id, bufferBChannel2);
            _commandBuffer.SetGlobalTexture(iChannel3Id, bufferBChannel3);
            _commandBuffer.Blit(_bufferB, _tempRenderTexture, bufferBMaterial);
            _commandBuffer.Blit(_tempRenderTexture, _bufferB);


            _commandBuffer.SetGlobalTexture(iChannel0Id, bufferCChannel0);
            _commandBuffer.SetGlobalTexture(iChannel1Id, bufferCChannel1);
            _commandBuffer.SetGlobalTexture(iChannel2Id, bufferCChannel2);
            _commandBuffer.SetGlobalTexture(iChannel3Id, bufferCChannel3);
            _commandBuffer.Blit(_bufferC, _tempRenderTexture, bufferCMaterial);
            _commandBuffer.Blit(_tempRenderTexture, _bufferC);


            _commandBuffer.SetGlobalTexture(iChannel0Id, bufferDChannel0);
            _commandBuffer.SetGlobalTexture(iChannel1Id, bufferDChannel1);
            _commandBuffer.SetGlobalTexture(iChannel2Id, bufferDChannel2);
            _commandBuffer.SetGlobalTexture(iChannel3Id, bufferDChannel3);
            _commandBuffer.Blit(_bufferD, _tempRenderTexture, bufferDMaterial);
            _commandBuffer.Blit(_tempRenderTexture, _bufferD);
            Camera.main.AddCommandBuffer(UnityEngine.Rendering.CameraEvent.AfterForwardAlpha, _commandBuffer);
        }
    }

    private void OnDisable()
    {
        iFrame = 0;
        ClearBuffer();
    }

    private void ClearBuffer()
    {
        if (_commandBuffer != null && Camera.main != null)
        {
            Camera.main.RemoveCommandBuffer(UnityEngine.Rendering.CameraEvent.AfterForwardAlpha, _commandBuffer);
            _commandBuffer = null;
        }
    }

    private bool _isLeftMouseDown = false;
    // Update is called once per frame
    void Update()
    {
        if(material != null)
        {
            if (channel0 != null)
            {
                material.SetTexture(iChannel0Id, channel0);
            }
            if (channel1 != null)
            {
                material.SetTexture(iChannel1Id, channel1);
            }
            if (channel2 != null)
            {
                material.SetTexture(iChannel2Id, channel2);
            }
            if (channel3 != null)
            {
                material.SetTexture(iChannel3Id, channel3);
            }
        }
        

        //getHours() * 3600.0 - getMinutes() * 60.0);

        Shader.SetGlobalFloatArray("iDate", new float[4] { 0, 0, 0, (float)System.DateTime.Now.Hour * 3600.0f + (float)System.DateTime.Now.Minute * 60.0f + System.DateTime.Now.Second });
        if(Input.GetMouseButtonDown(0))
        {
            _isLeftMouseDown = true;
        }
        if(Input.GetMouseButtonUp(0))
        {
            _isLeftMouseDown = false;
        }
        Shader.SetGlobalVector("iMouse", new Vector4(Mathf.Clamp(Input.mousePosition.x,0, Screen.width), Mathf.Clamp(Input.mousePosition.y,0, Screen.height), _isLeftMouseDown ? 1: 0));

        Shader.SetGlobalFloat("iTimeDelta", Time.deltaTime);

        Shader.SetGlobalFloat("iFrame", iFrame);
        iFrame++;
    }
}
