using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShaderManager : MonoBehaviour
{
    private int _shaderIndex = 0;
    private GameObject[] _GOArray;
    // Start is called before the first frame update
    void Start()
    {
        GameObject tGO = null;
        _GOArray =new GameObject[this.transform.childCount];
        for(int i =0; i< this.transform.childCount;i++)
        {
            tGO = this.transform.GetChild(i).gameObject;
            if(tGO.active)
            {
                _shaderIndex = i;
            }
            _GOArray[i] = tGO;
        }

        ShowByIndex(_shaderIndex);
    }

    // Update is called once per frame
    void Update()
    {
        if(Input.GetKeyDown(KeyCode.S))
        {
            ShowNext();
        }
        if(Input.GetKeyDown(KeyCode.W))
        {
            ShowPre();
        }
    }

    private void ShowPre()
    {
        if (_GOArray != null && _GOArray.Length > 0)
        {
            _shaderIndex--;
            if (_shaderIndex < 0)
            {
                _shaderIndex = _GOArray.Length - 1;
            }
            ShowByIndex(_shaderIndex);
        }
    }

    void ShowNext()
    {
        if (_GOArray != null && _GOArray.Length > 0)
        {
            _shaderIndex++;
            if (_shaderIndex > _GOArray.Length - 1)
            {
                _shaderIndex = 0;
            }
            ShowByIndex(_shaderIndex);
        }
    }

    private void ShowByIndex(int index)
    {
        if (_GOArray != null && index > -1 && index < _GOArray.Length)
        {
            for (int i = 0; i < _GOArray.Length; i++)
            {
                if (index == i)
                {
                    _GOArray[i].SetActive(true);
                }
                else
                {
                    _GOArray[i].SetActive(false);
                }
            }
        }
    }

    
}
