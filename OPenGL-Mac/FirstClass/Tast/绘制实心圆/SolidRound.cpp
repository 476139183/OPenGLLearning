//
//  SolidRound.cpp
//  Tast
//
//  Created by Yutian Duan on 2018/11/23.
//  Copyright © 2018年 Wanwin. All rights reserved.
//

#include "SolidRound.hpp"

#include "GUTHeader.h"

static void draw();

void solidRounds(int argc,char *argv[]) {
  
  //1.初始化一个glut库
  glutInit(&argc, (char **)argv);
  
  //2.创建一个窗口并设置名称
  glutCreateWindow("CC_Window");
  
  //3.绘图函数
  glutDisplayFunc(draw);
  
  
  //4.无限执行循环
  glutMainLoop();
  

}

static void draw() {
  //1.设置清屏颜色
  glClearColor(0.0, 0.0f, 0.0f, 0.0f);
  
  //2.执行清屏操作
  //GL_COLOR_BUFFER_BIT
  //GL_DEPTH_BUFFER_BIT
  //GL_STENCIL_BUFFER_BIT
  
  glClear(GL_COLOR_BUFFER_BIT);
  
  
  //3.设置绘图颜色
  glColor3f(1.0f, 0.0f, 0.0f);
  
  //设置绘图的坐标系统
  //左、右、上、下、近、远
  //glOrtho(0.0f, 1.0f, 0.0f, 1.0f, -1.0f, 1.0f);
  
  
  //开始渲染
  //GL_LINES 形成n/2条线条
  //GL_POINTS 把每个顶点作为一个点去处理。形成N个点
  //GL_LINE_STRIP 从第一个顶点到最后一个顶点连接成一组线段。n-1线段
  //GL_LINE_LOOP 从第一个顶点到最后一个顶点依次相连。n线程
  // glBegin(GL_TRIANGLE_FAN);
  glBegin(GL_POLYGON);
  
  
  //    //设置顶点
  //    glVertex3f(0.25f, 0.25f, 0.0);
  //    glVertex3f(0.75f, 0.25f, 0.0f);
  //    glVertex3f(0.75f, 0.75f, 0.0f);
  //    glVertex3f(0.25f, 0.75f, 0.0f);
  
  const int n = 55;
  
  const GLfloat R = 0.5f;
  const GLfloat pi = 3.1415926f;
  
  for (int i = 0; i < n; i++ ) {
    
    
    glVertex2f(R * cos(2 *pi /n * i), R * sin(2 * pi / n*i));
    
  }
  
  
  //结束渲染
  glEnd();
  
  
  glFlush();
  
}


