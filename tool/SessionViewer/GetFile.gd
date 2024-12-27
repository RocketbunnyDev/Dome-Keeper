extends HTTPRequest

func do(url):
	request(url, 
		Backend.header(), 
		true, 
		HTTPClient.METHOD_GET
	)
