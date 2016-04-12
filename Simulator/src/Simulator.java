import java.io.*;
import java.util.*;

public class Simulator {

	public static void main(String[] args) {
		if(args.length == 0) {
			System.out.println("User did not provide program on the command line");
			System.exit(0);
		}
		try {
			File progname = new File(args[0]);
			FileReader fileReader = new FileReader(progname);
			BufferedReader bufferedReader = new BufferedReader(fileReader);
			StringBuffer stringBuffer = new StringBuffer();
			String line;
			while ((line = bufferedReader.readLine()) != null) {
				stringBuffer.append(line);
				stringBuffer.append("\n");
			}
			fileReader.close();
			System.out.println(stringBuffer.toString());
		} catch (IOException e) {
			e.printStackTrace();
		}
		System.out.println("It worked");
		System.exit(0);
	}
	
}
