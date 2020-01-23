#include <string>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <iostream>

class FileReader
{
	private:
    const size_t chunkSize;
    char * chunk;
    FILE * inFile;
    size_t dataToConsume;
    size_t start;
    size_t end;
    bool good;
	public:
	FileReader(size_t chunkSize)
	:chunkSize(chunkSize), chunk(new char[2*chunkSize]),dataToConsume(0),start(0),end(0),good(false)
	{
      	inFile = stdin;
		good = true;
    }
    private:
	size_t readIn(char * buf, size_t bytesToRead)
	{
        return fread(buf,1,bytesToRead,inFile);
	}
	public:
	template <int N=1>
	bool readPast(char c)
	{
		int num = N;
		start = end;
		do{
			while(end < dataToConsume)
			{
				if(chunk[end++]==c&&((N==1)||(--num==0)))
					return true;
			}
			dataToConsume -= start;
			memcpy(chunk,&chunk[start],dataToConsume);
			end = end-start;
			start = 0;
		}while(dataToConsume < chunkSize && (dataToConsume += readIn(chunk+dataToConsume,chunkSize)));
		good = false;
		return false;
	}
	
	template <size_t N=1>
	bool skipPast(char c)
	{
		int num = N;
		start = end;
		do{
			while(end < dataToConsume)
			{
				if(chunk[end++]==c&&((N==1)||(--num==0)))
					return true;
			}
			end = 0;
			start = 0;
		}while((dataToConsume = readIn(chunk,chunkSize)));
		good = false;
		return false;
	}
	
	const char* getStartOfRead()
	{
		return &chunk[start];
	}
	
	size_t getCharactersInRead()
	{
		return end - start - 1;
	}
	
	bool isGood(){return good;}
};

void writeHeader(int numSamples)
{
    std::cout << "label";
    for(int i = 0; i < numSamples; ++i)
    {
        std::cout << ",s_" << i;
    }
    std::cout << std::endl;
}

static const int B64index[256] = { 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 62, 63, 62, 62, 63, 52, 53, 54, 55,
56, 57, 58, 59, 60, 61,  0,  0,  0,  0,  0,  0,  0,  0,  1,  2,  3,  4,  5,  6,
7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,  0,
0,  0,  0, 63,  0, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51 };

size_t b64decode(const void* data,char * str, const size_t len)
{
    unsigned char* p = (unsigned char*)data;
    int pad = len > 0 && (len % 4 || p[len - 1] == '=');
    const size_t L = ((len + 3) / 4 - pad) * 4;
    size_t strSize = L / 4 * 3 + pad - 1;
    size_t j = 0;
    for (size_t i = 0; i < L; i += 4)
    {
        int n = B64index[p[i]] << 18 | B64index[p[i + 1]] << 12 | B64index[p[i + 2]] << 6 | B64index[p[i + 3]];
        str[j++] = n >> 16;
        str[j++] = n >> 8 & 0xFF;
        str[j++] = n & 0xFF;
    }
    if (pad)
    {
        int n = B64index[p[L]] << 18 | B64index[p[L + 1]] << 12;
        str[j++] = n >> 16;

        if (len > L + 2 && p[L + 2] != '=')
        {
            n |= B64index[p[L + 2]] << 6;
            str[j++] = (n >> 8 & 0xFF);
        }
    }
    str[j] = '\0';
    return j;
}

void consumeLines(size_t samples)
{
    FileReader in(1000000);
    char * buf = new char[256+2*samples];//enough memory for samples + comma
    char * decodeBuf = new char[256+samples];
    char * current = buf;
    while(in.isGood())
    {
        in.skipPast<2>(' ');//skip past the spaces before and after the equals sign in 'label = '
        in.readPast('\n'); //read to the end of the line containing the label
        memcpy(buf,in.getStartOfRead(),in.getCharactersInRead());//write label to our buf
        current = buf + in.getCharactersInRead();//move current to after the label in buf
        in.skipPast<2>(' ');//skip past the 2 equals signs in 'values = '
        in.readPast('\n');//read to the end of the 64bit string
        size_t length = b64decode(in.getStartOfRead(),decodeBuf,in.getCharactersInRead());//decode the 64 bit string
        for(int i = 0;i < length;i++)//for each byte in the decoded string
        {
            current[2*i] = ',';//append a ','
            current[2*i+1] = decodeBuf[i]+'0';//and the character as a number 
        }
        current += 2*length;//move current to the end of the decoded 64bit string
        current[0] = '\n';//add the trailing newline character
        fwrite(buf,1,current-buf+1,stdout);//write the whole buff to stdout
        in.skipPast('l');//look for the next line, starts with an 'l' for 'label;
    }
    delete[] buf;
    delete[] decodeBuf;
}
int main(int argc, char *argv[])
{
    if(argc < 2)
    {
        std::cout << "supply number of samples" << std::endl;
    }
    size_t samples = atoi(argv[1]); 
    writeHeader(samples);
    consumeLines(samples);
    return 0;
}

