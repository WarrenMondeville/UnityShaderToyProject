using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MarioManager : MonoBehaviour
{

    private float _moveX = 0;
    private float _moveSpeed = 1;
    private bool _AKeyDown = false;
    private bool _DKeyDown = false;

    private bool _bigKey = false;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if(Input.GetKeyDown(KeyCode.A))
        {
            _AKeyDown = true;
        }
        if(Input.GetKeyUp(KeyCode.A))
        {
            _AKeyDown = false;
        }
        if(Input.GetKeyDown(KeyCode.D))
        {
            _DKeyDown = true;
        }
        if(Input.GetKeyUp(KeyCode.D))
        {
            _DKeyDown = false;
        }
        if(_AKeyDown)
        {
            _moveSpeed = -1;
            _moveX -= 1;
        }
        else if(_DKeyDown)
        {
            _moveSpeed = 1;
            _moveX += 1;
        }

        if(Input.GetKeyDown(KeyCode.F))
        {
            if(_bigKey)
            {
                _bigKey = false;
            }
            else
            {
                _bigKey = true;
            }

        }
        if(_bigKey)
        {
            Shader.SetGlobalFloat("_BigKey", 1);
        }
        else
        {
            Shader.SetGlobalFloat("_BigKey", -1);
        }
        Shader.SetGlobalFloat("_MoveSpeed", _moveSpeed);
        Shader.SetGlobalFloat("_MoveX", _moveX);
    }
}
