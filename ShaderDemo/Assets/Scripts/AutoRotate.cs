using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AutoRotate : MonoBehaviour
{
    public float speed = 10;


    void Update()
    {
        float y = transform.rotation.y;
        transform.Rotate(0, y + speed * Time.deltaTime, 0, Space.Self);
        // transform.rotation = Quaternion.Euler(0, y + speed * Time.deltaTime, 0);
    }
}
