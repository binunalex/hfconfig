<h1> Installation Instructions: </h1>

<h2> Solution based on Java: </h2>

The Lagrange interpolation is based on the [Rings](https://rings.readthedocs.io/en/latest/guide.html) library that implements a lot of numerical algebra methods.

First install [Java](https://www.oracle.com/java/technologies/downloads/).

Then import the Rings library either by downloading the [Jar](https://jar-download.com/artifacts/cc.redberry/rings/2.5.7) file or by means of e.g. Maven :

``` 
<dependency> 
       <groupId>cc.redberry</groupId> 
       <artifactId>rings</artifactId>
       <version>2.5.7</version> 
</dependency> 
``` 

Here is the Java code:

```
import cc.redberry.rings.*; 
import cc.redberry.rings.poly.*; 
import cc.redberry.rings.poly.univar.*; 
import cc.redberry.rings.poly.univar.UnivariateInterpolation.InterpolationZp64; 
import cc.redberry.rings.bigint.BigInteger; 
import static cc.redberry.rings.poly.PolynomialMethods.*; 
import static cc.redberry.rings.Rings.*; 
public class Main { 
        public static void main(String[] args) {   
		long[] points = {1L, 2L, 3L, 12L};  
		long[] values = {3L, 2L, 1L, 6L};  
		long point0=0L; 
		UnivariatePolynomialZp64 lagr = UnivariateInterpolation.interpolateLagrange(997, points, values); 
		long v1 = result.evaluate(point0); 
		System.out.println(v1); 
	}  
 }  
```


 

