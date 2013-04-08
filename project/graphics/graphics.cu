#include <GL/glew.h>
#include <GL/glut.h>
#include <cuda.h>
#include <cuda_gl_interop.h>
#include <stdio.h>
#include "graphics.h"
#include "../headers/particle.h"

void (*cudaFunc)(float3 *) = NULL;

GLuint VAO;
GLuint posBuffer;

cudaGraphicsResource * posCUDA;
float3 * pos;

void createVBO() {
	glGenVertexArrays(1, &VAO);
	glBindVertexArray(VAO);
	glGenBuffers(1, &posBuffer);
	glEnableVertexAttribArray(0);
	glEnableVertexAttribArray(1);
	
	glBindBuffer(GL_ARRAY_BUFFER, posBuffer);
	glBufferData(GL_ARRAY_BUFFER, 3*PARTICLE_COUNT*sizeof(float), 0, GL_DYNAMIC_DRAW);
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
	
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glDisableVertexAttribArray(0);
	glDisableVertexAttribArray(1);
}

void initGLDevice() {
	cudaDeviceProp prop;
	int dev;
	memset(&prop, 0, sizeof(cudaDeviceProp));
	prop.major = 1;
	prop.minor = 0;
	cudaChooseDevice(&dev, &prop);
}

void initGLUT() {
	int k = 0;
	glutInit(&k, NULL);
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA);
	glutInitWindowSize(WINDOW_DIM, WINDOW_DIM);
	glutCreateWindow("Window");
	glewInit();
}

void registerResources() {
	size_t size;
	
	cudaGraphicsGLRegisterBuffer(&posCUDA, posBuffer, cudaGraphicsRegisterFlagsNone);
	cudaGraphicsMapResources(1, &posCUDA, 0);
	cudaGraphicsResourceGetMappedPointer((void**)&pos, &size, posCUDA);
	cudaMemset((void*)pos, 0, PARTICLE_COUNT * sizeof(float3));
	cudaGraphicsUnmapResources(1, &posCUDA, 0);
}

void drawParticles() {
	glClear(GL_COLOR_BUFFER_BIT);

	glBindVertexArray(VAO);
	glEnableVertexAttribArray(0);
	glBindBuffer(GL_ARRAY_BUFFER, posBuffer);
	glDrawArrays(GL_POINTS, 0, PARTICLE_COUNT);
	glDisableVertexAttribArray(0);
	glBindVertexArray(0);
	glutPostRedisplay();
}

void display() {
	size_t size;
	
	cudaGraphicsMapResources(1, &posCUDA, 0);
	cudaGraphicsResourceGetMappedPointer((void**)&pos, &size, posCUDA);
	if (cudaFunc) {
		cudaFunc(pos);
	}
	cudaGraphicsUnmapResources(1, &posCUDA, 0);

	drawParticles();
	
	glutSwapBuffers();
	glutPostRedisplay();
}

void initGraphics() {
	initGLDevice();
	initGLUT();
	createVBO();
	registerResources();
	glutDisplayFunc(display);
}
