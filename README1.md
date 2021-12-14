<h1> Installation Instructions: </h1>

<h2> Solution based on Java: </h2>

The solution is based on the [Rings](https://rings.readthedocs.io/en/latest/guide.html) library

First install [Java](https://www.oracle.com/java/technologies/downloads/).

Then import the Rings library by means of e.g. Maven :

``` <dependency> ``` <br>
```    <groupId>cc.redberry</groupId> ``` <br>
```    <artifactId>rings</artifactId> ``` <br>
```    <version>2.5.7</version> ``` <br>
``` </dependency> ``` <br>

Save this code in the script **first.sage**. It can be executed from the command line using the command ```sage /path/to/myscript.sage```.

The goal is to use the numerical analysis features of Sage that are not implemented in Java. From a Java module, you will run a Sage script with the relevant function (Lagrange [interpolation]). The output of Lagrange interpolation is captured by your Java:

 ```public class ProcessOutputExample {   ``` <br>
 ```   public static void main(String[] arguments) throws IOException,InterruptedException { ``` <br>
            ```     System.out.println(getProcessOutput()); ``` <br>
        ```   } ```  <br>

    public static String getProcessOutput() throws IOException, InterruptedException {
         ProcessBuilder processBuilder = new ProcessBuilder("sage", "first.sage");

         processBuilder.redirectErrorStream(true);

         Process process = processBuilder.start();
         StringBuilder processOutput = new StringBuilder();

         try (BufferedReader processOutputReader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
             String readLine;

             while ((readLine = processOutputReader.readLine()) != null)
                  processOutput.append(readLine + System.lineSeparator());
            process.waitFor();
         }

         return processOutput.toString().trim();
    }}

