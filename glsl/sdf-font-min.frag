// made by madblobfish and @literallylara (twitter)

#define SC 0.07 // line scale
#define LW 0.03 // line width

// line segment
float l(vec2 p, float ax, float ay, float bx, float by){
	vec2 z = floor(p*500.+.5)/500.,
		 a = vec2(ax,ay)*SC,
		 b = vec2(bx,by)*SC,
		 ab = b-a;
	return length(z-a-ab*clamp(dot(z-a,ab)/dot(ab,ab),0.,1.))-LW;
}

#define C0(L) float L (vec2 p){return min(l(p,
#define C1 ),min(l(p,
#define C2 ))));}
#define C3 ),l(p,
#define C4 1.,-8.,5.,-8.
#define C5 1.,-1.5,1.,-8.
#define C6 5.,-1.5,1.,-1.5
#define C7 5.,-8.,5.,-1.5
C0(Y) 1.,-1.5,3.,-5. C1 3.,-5.,3.,-8. C3 3.,-5.,5.,-1.5)));}
C0(V) 1.,-1.5,3.,-8. C3 3.,-8.,5.,-1.5));}
C0(X) 1.,-1.5,5.,-8. C3 5.,-1.5,1.,-8.));}
C0(M) 1.,-8.,1.,-1.5 C1 1.,-1.5,3.,-4. C1 3.,-4.,5.,-1.5 C3 C7 C2
C0(A) C6 C1 C7 C1 1.,-8.,1.,-1.5 C3 1.,-5.,5.,-5. C2
C0(R) 1.,-8.,1.,-1.5 C1 1.,-1.5,5.,-1.5 C1 5.,-1.5,5.,-5. C1 1.,-5.,5.,-5. C3 3.5,-5.,5.,-8.) C2
C0(P) 1.,-8.,1.,-1.5 C1 1.,-1.5,5.,-1.5 C1 5.,-1.5,5.,-5. C3 5.,-5.,1.,-5. C2
C0(N) 1.,-8.,1.,-1.5 C1 1.,-1.5,5.,-8. C3 C7 )));}
C0(I) 1.5,-1.5,4.5,-1.5 C1 3.,-1.5,3.,-8. C3 1.5,-8.,4.5,-8.)));}
C0(J) 1.5,-8.,3.,-8. C1 3.,-8.,4.,-7. C1 4.,-7.,4.,-1.5 C3 4.,-1.5,1.5,-1.5 C2
C0(T) 3.,-8.,3.,-1.5 C3 1.,-1.5,5.,-1.5));}
C0(Z) C4 C1 1.,-1.5,5.,-1.5 C3 5.,-1.5,1.,-8.)));}
C0(B) C4 C1 C5 C1 4.,-5.,4.,-1.5 C1 4.,-1.5,1.,-1.5 C1 5.,-8.,5.,-5. C3 5.,-5.,1.,-5.)) C2
C0(G) C4 C1 C5 C1 C6 C1 5.,-2.5,5.,-1.5 C1 5.,-8.,5.,-5. C3 5.,-5.,3.5,-5.)) C2
C0(Q) C4 C1 C5 C1 C6 C1 C7 C3 5.,-8.,3.5,-6.5) C2
C0(O) C4 C1 C5 C1 C6 C3 C7 C2
C0(U) C4 C1 C5 C3 C7 )));}
C0(C) C4 C1 C5 C3 C6 )));}
C0(E) C4 C1 C6 C1 1.,-5.,3.,-5. C3 1.,-1.5,1.,-8. C2
C0(K) C5 C1 1.,-5.,2.5,-5. C1 2.5,-5.,5.,-1.5 C3 2.5,-5.,5.,-8. C2
C0(H) C5 C1 C7 C1 1.,-5.,5.,-5. C3 5.,-5.,5.,-1.5 C2
C0(W) C5 C1 C7 C1 1.,-8.,3.,-6. C3 3.,-6.,5.,-8. C2
C0(D) C5 C1 1.,-8.,4.,-8. C1 4.,-8.,4.5,-7.5 C1 4.5,-7.5,5.,-6.25 C1 5.,-6.25,5.,-3.75 C1 5.,-3.75,4.5,-2. C1 4.5,-2.,4.,-1.5 C3 4.,-1.5,1.,-1.5 )))) C2
C0(L) C5 C3 C4 ));}
C0(F) C6 C1 3.,-5.,1.,-5. C3 1.,-1.5,1.,-8.)));}
C0(S) C6 C1 1.,-1.5,1.,-5. C1 1.,-5.,5.,-5. C1 5.,-5.,5.,-8. C3 5.,-8.,1.,-8.) C2

// usage example
void mainImage( out vec4 fragColor, in vec2 fragCoord ){
	float t = iTime;
	vec2 uv = (2.0 * fragCoord.xy - iResolution.xy) / iResolution.yy;

	uv.x += 0.13;
	uv.x *= abs(sin(uv.x+t*2.0)*0.5+1.0)+1.0;
	uv.y *= abs(sin(uv.x+t*2.0)+1.0)+1.0;

	vec3 col = vec3(0);
	float d = 1.0;

	d = min(d,D(uv-vec2(-2.0,0.5)));
	d = min(d,E(uv-vec2(-1.5,0.5)));
	d = min(d,M(uv-vec2(-1.0,0.5)));
	d = min(d,O(uv-vec2(-0.5,0.5)));
	d = min(d,S(uv-vec2( 0.0,0.5)));
	d = min(d,C(uv-vec2( 0.5,0.5)));
	d = min(d,E(uv-vec2( 1.0,0.5)));
	d = min(d,N(uv-vec2( 1.5,0.5)));
	d = min(d,E(uv-vec2( 2.0,0.5)));

	col = mix(vec3(1),col,smoothstep(d,d+0.01,0.0));

	fragColor = vec4(vec3(1.-40.0*d),1.0);
}
