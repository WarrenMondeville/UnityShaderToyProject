using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.UI;
#if UNITY_EDITOR
using UnityEditor;
#endif

[ExecuteInEditMode]
[AddComponentMenu("UI/ColorPanel")]
public class ColorPanel: MaskableGraphic
{
    public bool m_IsEffect = false;
    public Texture texture;
    public float m_InvFade = 1;
    public Vector4 m_MainTexST = new Vector4(1, 1, 0, 0);
    public Vector4 m_MaskTexST = new Vector4(1, 1, 0, 0);
    public Color m_TintColor = Color.white;
    public Image img;
    Transform m_transform;
    private Material m_matForRendering = null;

    private bool m_bMatDirty = true;

    public Vector3 circleCenter = new Vector3();

    public float startDist = 100;
    public float spaceDist = 10;

    public int tileNumW = 32;
    public int tileNumH = 8;

    public float animationSpeed = 0.5f;

    private Vector3[] _rectVertices;
    private Vector3[] _circleVertices;
    private Vector3[] _pointVertices;

    private Vector3[] _srcVertices;
    private Vector3[] _destVertices;//目标数组

    private Vector3[] _currVertices;

    private Vector2[] _uvs;
    private int[] _indexArray;
    private Color[] _colors;

    private float[] _currOffsetArray;//记录当前时间的

    public int rectW = 100;
    public int rectH = 100;

    private float _startTime = 0;

    public Canvas canvas;

    public override Texture mainTexture
    {
        get
        {
            return texture;
        }
    }
    [SerializeField]
    public override Material material
    {
        get
        {
            return base.material;
        }
        set
        {
            base.material =  value;
            m_bMatDirty = true;
        }
    }

    public Material MatForRendering
    {
        get
        {
            if (m_bMatDirty)
            {
                m_matForRendering = materialForRendering;
                m_bMatDirty = false;
            }
            return m_matForRendering;
        }
    }

    Transform _transform
    {
        get
        {
            if (m_transform == null)
                m_transform = transform;
            return m_transform;
        }
    }

    protected override void OnPopulateMesh(VertexHelper vh)
    {
        vh.Clear();

            float scale = Mathf.Min(rectTransform.rect.width, rectTransform.rect.height);
            for (int i = 0; i < _currVertices.Length; ++i)
            {
                UIVertex vect = UIVertex.simpleVert;
                vect.position = _currVertices[i] * scale;
                vect.uv0 = _uvs[i];
                vect.color = m_TintColor;
                vh.AddVert(vect);
            }
            for (int i = 0; i < _indexArray.Length / 3; ++i)
            {
                int i0 = _indexArray[i * 3];
                int i1 = _indexArray[i * 3 + 1];
                int i2 = _indexArray[i * 3 + 2];
                vh.AddTriangle(i0, i1, i2);
            }
    }

    protected override void Awake()
    {
        raycastTarget = false;
    }

    protected override void OnEnable()
    {
        base.OnEnable();
        m_bMatDirty = true;

        CreateTexture2D();//创建彩色贴图

        int tTileNumW = tileNumW;//创建临时变量获取定义好的宽度
        int tVerticesNum = tTileNumW * tileNumH * 4;//顶点数
        Vector2[] tAngleArray = new Vector2[tVerticesNum];//存储角度数组
        _pointVertices = new Vector3[tVerticesNum];//存储归零的顶点数据
        _circleVertices = new Vector3[tVerticesNum];//存储圆形顶点数据
        _rectVertices = new Vector3[tVerticesNum];//存储方形顶点数据
        _currVertices = new Vector3[tVerticesNum];//
        _currOffsetArray = new float[tVerticesNum];//
        _colors = new Color[tileNumH * tileNumW];
        _uvs = new Vector2[tVerticesNum];//存储UV的数组
        for (int i = 0;i < tileNumH; i++)
        {
            for(int j = 0;j < tileNumW; j++)
            {
                
                int tIndexX = Mathf.FloorToInt((float)j / (float)tileNumW * 360.0f);
                int tIndexY = 100 - Mathf.FloorToInt(i  / (float)tileNumH * 100.0f);
                _colors[i * tileNumW + j] = HslToRgb(tIndexX, tIndexY, 100);
                int tDistance = i; 
                if (i == 0)
                {
                    tDistance = i - 1;
                    //绘制出内圈
                }
                int tIndex = (i * tileNumW + j) * 4;
                float lerpAngle = 1.0f / (float)tileNumW * Mathf.PI * 2.0f;
                //绘制角度
                tAngleArray[tIndex + 0] = new Vector2((float)j / (float)tileNumW * Mathf.PI * 2.0f, tDistance);
                tAngleArray[tIndex + 1] = new Vector2((float)(j+1) /(float)tileNumW * Mathf.PI * 2.0f, tDistance);
                tAngleArray[tIndex + 2] = new Vector2((float)j / (float)tileNumW * Mathf.PI * 2.0f, tDistance + 1);
                tAngleArray[tIndex + 3] = new Vector2((float)(j+1) / (float)tileNumW * Mathf.PI * 2.0f, tDistance + 1);
                //绘制正方形顶点
                _rectVertices[tIndex + 0] = new Vector3(j / (float)tileNumW * rectW , (i+1) / (float)tileNumH * rectH, 0);
                _rectVertices[tIndex + 1] = new Vector3((j+1) / (float)tileNumW * rectW, (i+1) / (float)tileNumH * rectH, 0);
                _rectVertices[tIndex + 2] = new Vector3(j / (float)tileNumW * rectW, i / (float)tileNumH * rectH, 0);
                _rectVertices[tIndex + 3] = new Vector3((j+1) / (float)tileNumW * rectW, i / (float)tileNumH * rectH, 0);
                //绘制UV
                _uvs[tIndex + 0] = new Vector2((float)j / (float)tileNumW, (float)(i+1) / (float)tileNumH);
                _uvs[tIndex + 1] = new Vector2((float)(j+1) / (float)tileNumW, (float)(i+1) / (float)tileNumH);
                _uvs[tIndex + 2] = new Vector2((float)j / (float)tileNumW, (float)(i) / (float)tileNumH);
                _uvs[tIndex + 3] = new Vector2((float)(j+1) / (float)tileNumW, (float)(i) / (float)tileNumH);
            }
        }


        for(int i = 0;i < tAngleArray.Length;i++)
        {
            float tDistance = startDist + spaceDist * tAngleArray[i].y;
            Vector3 tPos = circleCenter + new Vector3(Mathf.Cos(tAngleArray[i].x) * tDistance, Mathf.Sin(tAngleArray[i].x) * tDistance, 0);
            float tCurLength = Mathf.Cos(tAngleArray[i].x) * tDistance;

            //To Calculate index
            _circleVertices[i] = tPos;
            _pointVertices[i] = Vector3.zero;
            _currVertices[i] = Vector3.zero;
        }

        //绘制三角形数组
        _indexArray = new int[tileNumW * tileNumH * 6];

        int[] tExIndexArray = new int[6] { 0, 1, 2, 2, 1, 3 };

        for(int i = 0;i < tileNumH; i++)
        {
            for(int j = 0;j < tileNumW; j++)
            {
                int tIndex = i * tileNumW + j;
                for (int h = 0;h < tExIndexArray.Length;h++)
                {
                    _indexArray[tIndex * 6 + h] = tIndex * 4 + tExIndexArray[h];
                }
            }
        }
        _srcVertices = _destVertices = _pointVertices;
        Update();
    }
    Material forRendering;

    void Update()
    {
        if (!gameObject.activeInHierarchy)
            return;

        if (MatForRendering == null)
            return;
        if(forRendering == null && Application.isPlaying)
        {
            forRendering = new Material(material);
            material = forRendering;
            forRendering = MatForRendering;
        }
        else
        {
            forRendering = MatForRendering;
        }

        if (Input.GetKeyDown(KeyCode.A))
        {
            _startTime = Time.realtimeSinceStartup;
            RandomOffset(0);
            _srcVertices = _destVertices;
            _destVertices = _pointVertices;
        }
        if (Input.GetKeyDown(KeyCode.S))
        {
            _startTime = Time.realtimeSinceStartup;
            RandomOffset(0);
            _srcVertices = _destVertices;
            _destVertices = _circleVertices;
        }
        if (Input.GetKeyDown(KeyCode.D))
        {
            _startTime = Time.realtimeSinceStartup;
            RandomOffset(1);
            _srcVertices = _destVertices;
            _destVertices = _rectVertices;
        }
        if (_srcVertices != null && _destVertices != null)
        {
            for (int i = 0; i < _currVertices.Length; i++)
            {
                _currVertices[i] = LerpVertices(_srcVertices[i], _destVertices[i], Mathf.Clamp((Time.realtimeSinceStartup - _currOffsetArray[i] - _startTime) / animationSpeed, 0.0f, 1.0f));
            }
            this.SetVerticesDirty();
        }
       

        
        //Debug.Log("=====" + tLerpOfCurPos);
        if (Input.GetMouseButtonDown(0))
        {
            CalculateCurPos(Input.mousePosition, rectTransform.position);

            //float tLerpOfCurPos = Mathf.Atan2(tLerpPos.y, tLerpPos.x);
            //lerpOfCurPos = tLerpOfCurPos;
        }
    }
    public Color GetSelectColor(int curIndexX , int curIndexY)
    {
        if (curIndexY == -1)
        {
            curIndexY = 0;
        }
        if (curIndexX <0)
        {
            curIndexX = tileNumW + curIndexX;
        }
        int tIndex = Mathf.Clamp((curIndexY * tileNumW + curIndexX) - 1 , 0 , (tileNumH * tileNumW-1));
        Color tColor= _colors[tIndex];
        if (tColor != null)
        {
            img.color = tColor;
        }
        //Debug.Log("Color is ==== " + tColor.ToString());
        return tColor;
    
    }
    public Vector3 ScreenPosToCanvasPos(Vector3 screenPos)
    {
        Vector3 tCanvasPos;
        Vector3 canvasWH = new Vector3(622, 350, 0);
        
        if(canvas != null)
        {
            canvasWH.x = this.canvas.pixelRect.width;
            canvasWH.y = this.canvas.pixelRect.height;
        }
        Vector3 tPercent = new Vector3(canvasWH.x / Screen.width, canvasWH.y / Screen.height, 0);
        tCanvasPos = new Vector3(screenPos.x * tPercent.x - canvasWH.x / 2 , screenPos.y * tPercent.y - canvasWH.y / 2, 0);

        return tCanvasPos;
    }
    public Color CalculateCurPos(Vector3 mousePos , Vector3 rectTrans)
    {
        Vector3 tCanvasPos = ScreenPosToCanvasPos(mousePos);
        Vector3 tCanvasRect = ScreenPosToCanvasPos(rectTrans);
        Vector3 tLerpNum = mousePos - rectTrans;
        float tLerpAngle =  Mathf.Atan2(tLerpNum.y,tLerpNum.x);
        int _curColorX = Mathf.CeilToInt((float)tLerpAngle / (1.0f / (float)tileNumW * Mathf.PI * 2.0f));
        float tDistance = Vector3.Distance(tCanvasPos, tCanvasRect);
        int _curColorY = Mathf.CeilToInt((float)(tDistance - startDist * 100.0f) / (spaceDist * 100.0f));
        Color curSelectColor = GetSelectColor(_curColorX, _curColorY);
        return curSelectColor;
    }

    private void RandomOffset(int type)
    {

        switch (type)
        {
            case 0:
                {
                    float[] tTimeOffsetArray = new float[tileNumW];
                    for (int i = 0; i < tileNumW; i++)
                    {
                        tTimeOffsetArray[i] = UnityEngine.Random.Range(0.0f, 1.0f) * animationSpeed;
                    }

                    float tTimeOffset = 0;
                    for (int i = 0; i < tileNumH; i++)
                    {
                        for (int j = 0; j < tileNumW; j++)
                        {
                            int tIndex = i * tileNumW + j;
                            tTimeOffset = tTimeOffsetArray[j];
                            _currOffsetArray[tIndex * 4] = _currOffsetArray[tIndex * 4 + 1] = _currOffsetArray[tIndex * 4 + 2] = _currOffsetArray[tIndex * 4 + 3] = tTimeOffset;
                        }
                    }
                }

                break;
            case 1:
                {
                    float tTimeOffset = 0;
                    for (int i = 0; i < tileNumH; i++)
                    {
                        for (int j = 0; j < tileNumW; j++)
                        {
                            int tIndex = i * tileNumW + j;
                            tTimeOffset += 0.01f;
                            _currOffsetArray[tIndex * 4] = _currOffsetArray[tIndex * 4 + 1] = _currOffsetArray[tIndex * 4 + 2] = _currOffsetArray[tIndex * 4 + 3] = tTimeOffset;
                        }
                    }
                }

                break;
        }
    }

    public Vector3 LerpVertices(Vector3 srcPos, Vector3 destPos, float lerp)
    {
        return srcPos * (1 - lerp) + destPos * lerp;
    }

    private void CreateTexture2D()
    {
        Texture2D tTexture = new Texture2D(1024, 1024, TextureFormat.ARGB32, false, false);
        int tW = tTexture.width / tileNumW;
        int tH = tTexture.height / tileNumH;

        for (int i = 0; i < tTexture.height; i++)
        {
            for (int j = 0; j < tTexture.width; j++)
            {
                int tIndexX = Mathf.FloorToInt(j / tW / (float)tileNumW * 360.0f);
                int tIndexY = 100 - Mathf.FloorToInt(i / tH / (float)tileNumH * 100.0f);
                tTexture.SetPixel(j, i, HslToRgb(tIndexX, tIndexY, 100));
            }
        }
        tTexture.Apply();
        this.texture = tTexture;
    }


    public Color HslToRgb(int Hue, int Saturation, int Lightness)
    {
        float num4 = 0.0f;
        float num5 = 0.0f;
        float num6 = 0.0f;
        float num = ((float)Hue) % 360.0f;
        float num2 = ((float)Saturation) / 100.0f;
        float num3 = ((float)Lightness) / 100.0f;
        if (num2 == 0.0)
        {
            num4 = num3;
            num5 = num3;
            num6 = num3;
        }
        else
        {
            float d = num / 60.0f;
            int num11 = (int)Mathf.Floor(d);
            float num10 = d - num11;
            float num7 = num3 * (1.0f - num2);
            float num8 = num3 * (1.0f - (num2 * num10));
            float num9 = num3 * (1.0f - (num2 * (1.0f - num10)));
            switch (num11)
            {
                case 0:
                    num4 = num3;
                    num5 = num9;
                    num6 = num7;
                    break;
                case 1:
                    num4 = num8;
                    num5 = num3;
                    num6 = num7;
                    break;
                case 2:
                    num4 = num7;
                    num5 = num3;
                    num6 = num9;
                    break;
                case 3:
                    num4 = num7;
                    num5 = num8;
                    num6 = num3;
                    break;
                case 4:
                    num4 = num9;
                    num5 = num7;
                    num6 = num3;
                    break;
                case 5:
                    num4 = num3;
                    num5 = num7;
                    num6 = num8;
                    break;
            }
        }
        return new Color(num4, num5, num6);
    }

#if UNITY_EDITOR
    [MenuItem("GameObject/UI/ColorPanel")]
    static void CreateUIMesh()
    {
        if (Selection.activeGameObject == null)
            return;
        RectTransform parent = Selection.activeGameObject.GetComponent<RectTransform>();
        if (parent == null)
            return;
        GameObject go = new GameObject("ColorPanel");
        RectTransform rt = go.AddComponent<RectTransform>();
        ColorPanel xuimesh = go.AddComponent<ColorPanel>();
        xuimesh.raycastTarget = false;
        rt.SetParent(parent);
        rt.localPosition = Vector3.zero;
        rt.localScale = Vector3.one;
        rt.localRotation = Quaternion.identity;
        Selection.activeGameObject = go;
    }

    [MenuItem("Assets/CopyPrefabToUIMode")]
    static void CopyPrefabToUIMode()
    {
        if (Selection.activeObject == null)
            return;
        if (!(Selection.activeObject is GameObject))
            return;
        GameObject rawPrefab = (GameObject)Selection.activeObject;
        MeshRenderer renderer = rawPrefab.GetComponentInChildren<MeshRenderer>();
        MeshFilter meshFilter = rawPrefab.GetComponentInChildren<MeshFilter>();
        if (renderer == null || meshFilter == null)
        {
            //Debug.Log.I("未找到合适的Renderer和MeshFilter");
            return;
        }
        Material mat = renderer.sharedMaterial;
        Mesh mesh = meshFilter.sharedMesh;

        string matPath = AssetDatabase.GetAssetPath(mat);
        string meshPath = AssetDatabase.GetAssetPath(mesh);
        string prefabPath = AssetDatabase.GetAssetPath(Selection.activeObject);
        //LiteCommon.BLog.I("Copy prefab with " + matPath + " and " + meshPath);

        //创建prefab根物体
        GameObject root = new GameObject();
        root.AddComponent<RectTransform>();
        Selection.activeGameObject = root;

        //创建UIMesh子物体
        CreateUIMesh();
        if (Selection.activeGameObject == null || Selection.activeGameObject.GetComponent<ColorPanel>() == null)
        {
            Debug.LogError("创建UIMesh对象失败了");
            return;
        }
        ColorPanel uiMesh = Selection.activeGameObject.GetComponent<ColorPanel>();
        uiMesh.texture = mat.mainTexture;
        uiMesh.transform.localScale = new Vector3(0.1f, 0.1f, 0.1f);
        uiMesh.transform.localEulerAngles = new Vector3(24, -213, -13);

        PrefabUtility.CreatePrefab(GetAssetsPathWithUI(prefabPath), root);
        GameObject.DestroyImmediate(root);
    }

    static string GetAssetsPathWithUI(string assetPath)
    {
        int n = assetPath.LastIndexOf('.');
        return assetPath.Substring(0, n) + "_ui" + assetPath.Substring(n);
    }

#endif
}
