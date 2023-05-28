package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"sort"
	"strconv"
	"time"
)

type Duration struct {
	Second int64 `json:"seconds"`
	Minute int64 `json:"minutes"`
	Hour   int64 `json:"hours"`
}

func (d Duration) toSeconds() int64 {
	return d.Second + d.Minute*60 + d.Hour*3600
}

func timeSpan(t1 Time, t2 Time) Duration {
	secs := t2.toISO() - t1.toISO()
	return fromSeconds(secs)
}

func fromSeconds(seconds int64) Duration {
	hours := seconds / 3600
	seconds -= hours * 3600
	minutes := seconds / 60
	seconds -= minutes * 60
	return Duration{
		Second: seconds,
		Minute: minutes,
		Hour:   hours,
	}
}

func (t Duration) Add(other Duration) Duration {
	return fromSeconds(t.toSeconds() + other.toSeconds())
}

func (t Duration) Subtract(other Duration) Duration {
	return fromSeconds(t.toSeconds() - other.toSeconds())
}

type Time struct {
	Year   int `json:"year"`
	Month  int `json:"month"`
	Day    int `json:"day"`
	Hour   int `json:"hour"`
	Minute int `json:"minute"`
	Second int `json:"second"`
}

func (t Time) getPreviousDay() Time {
	t2 := fromISO(t.toISO() - 86400)
	return t2
}

func (t Time) FileName() string {
	//Check if timeblocks folder exists
	if _, err := os.Stat("timeblocks"); os.IsNotExist(err) {
		err = os.Mkdir("timeblocks", 0755)
		if err != nil {
			log.Fatal(err)
		}
	}
	return fmt.Sprintf("timeblocks/%d-%02d-%02d.json", t.Year, t.Month, t.Day)
}

func (t Time) toISO() int64 {
	timeObj := time.Date(t.Year, time.Month(t.Month), t.Day, t.Hour, t.Minute, t.Second, 0, time.UTC)
	unixTimestamp := timeObj.Unix()
	return unixTimestamp
}

func fromISO(timestamp int64) Time {
	// Create a time.Time object from the Unix timestamp
	timeObj := time.Unix(timestamp, 0)

	// Extract the individual components from the time.Time object
	year := timeObj.Year()
	month := int(timeObj.Month())
	day := timeObj.Day()
	hour := timeObj.Hour()
	minute := timeObj.Minute()
	second := timeObj.Second()

	// Create and return the Time struct
	return Time{
		Year:   year,
		Month:  month,
		Day:    day,
		Hour:   hour,
		Minute: minute,
		Second: second,
	}
}

func (t Time) Add(d Duration) Time {
	t2 := fromISO(t.toISO() + d.toSeconds())
	return t2
}

func (t Time) Before(other Time) bool {
	return t.toISO() < other.toISO()
}

func (t Time) After(other Time) bool {
	return t.toISO() > other.toISO()
}

func (t Time) Equal(other Time) bool {
	return t.toISO() == other.toISO()
}

type BlockType struct {
	ID    int    `json:"id"`
	Name  string `json:"name"`
	Color Color  `json:"color"`
}

type Color struct {
	R int `json:"r"`
	G int `json:"g"`
	B int `json:"b"`
}

func (b BlockType) Save() error {
	file, err := os.OpenFile("blocktypes.json", os.O_RDWR, 0644)
	if err != nil {
		// If the file does not exist, create it
		if os.IsNotExist(err) {
			file, err = os.Create("blocktypes.json")
			if err != nil {
				return err
			}
		} else {
			return err
		}
	}
	defer file.Close()

	// Get all block types
	blockTypes, err := getBlockTypes()
	if err != nil {
		return err
	}

	// Check if the block type already exists
	if b.CheckIdentical(blockTypes) {
		err = fmt.Errorf("block type already exists")
		return err
	}

	// Add the new block type to the slice
	blockTypes = append(blockTypes, b)

	// Encode the block types into JSON and write to the file
	encoder := json.NewEncoder(file)
	err = encoder.Encode(blockTypes)
	if err != nil {
		return err
	}

	return nil
}

func (b BlockType) CheckIdentical(blockTypes []BlockType) bool {
	identical := false
	for _, blockType := range blockTypes {
		if blockType.Name == b.Name {
			identical = true
			break
		}
		if blockType.Color.R == b.Color.R &&
			blockType.Color.G == b.Color.G &&
			blockType.Color.B == b.Color.B {
			identical = true
			break
		}
		if blockType.ID == b.ID {
			fmt.Println("Something went wrong. Two block types have the same ID.")
			identical = true
			break
		}

	}
	return identical
}

func getBlockTypes() ([]BlockType, error) {
	file, err := os.OpenFile("blocktypes.json", os.O_RDWR, 0644)
	if err != nil {
		//If file doesn't exist create an empty json array in it
		if os.IsNotExist(err) {
			file, err = os.Create("blocktypes.json")
			if err != nil {
				return nil, err
			}
			_, err = file.WriteString("[{\"id\": 0, \"name\": \"System\", \"color\": {\"r\": 20, \"g\": 20, \"b\": 200}}]")
			if err != nil {
				return nil, err
			}

			var newBlockType = BlockType{
				ID:   0,
				Name: "System",
				Color: Color{
					R: 20,
					G: 20,
					B: 200,
				},
			}
			var newBlockTypes []BlockType
			newBlockTypes = append(newBlockTypes, newBlockType)
			return newBlockTypes, nil
		} else {
			return nil, err
		}
	}
	defer file.Close()

	// Decode the JSON into a slice of block types
	var blockTypes []BlockType
	decoder := json.NewDecoder(file)
	err = decoder.Decode(&blockTypes)
	if err != nil {
		return nil, err
	}

	return blockTypes, nil
}

// TimeBlock represents the structure of a time block
type TimeBlock struct {
	StartTime   Time   `json:"startTime"`
	EndTime     Time   `json:"endTime"`
	BlockTypeID int    `json:"blockTypeId"`
	Title       string `json:"title"`
}

func (t TimeBlock) Duration() Duration {
	return timeSpan(t.StartTime, t.EndTime)
}

func CheckOverlaps(t []TimeBlock) bool {
	for i, block := range t {
		for j := i + 1; j < len(t); j++ {
			if block.StartTime.Year == t[j].StartTime.Year &&
				block.StartTime.Month == t[j].StartTime.Month &&
				block.StartTime.Day == t[j].StartTime.Day &&
				((block.StartTime.Hour < t[j].EndTime.Hour) ||
					(block.StartTime.Hour == t[j].EndTime.Hour && block.StartTime.Minute < t[j].EndTime.Minute)) &&
				((block.EndTime.Hour > t[j].StartTime.Hour) ||
					(block.EndTime.Hour == t[j].StartTime.Hour && block.EndTime.Minute > t[j].StartTime.Minute)) {
				return true
			}
		}
	}
	return false
}

func CheckNewOverlap(ts []TimeBlock, t TimeBlock) bool {
	for _, block := range ts {
		if block.StartTime.Year == t.StartTime.Year &&
			block.StartTime.Month == t.StartTime.Month &&
			block.StartTime.Day == t.StartTime.Day &&
			((block.StartTime.Hour < t.EndTime.Hour) ||
				(block.StartTime.Hour == t.EndTime.Hour && block.StartTime.Minute < t.EndTime.Minute)) &&
			((block.EndTime.Hour > t.StartTime.Hour) ||
				(block.EndTime.Hour == t.StartTime.Hour && block.EndTime.Minute > t.StartTime.Minute)) {
			return true
		}
	}
	return false
}

func (t TimeBlock) Save() error {
	// Get all time blocks for the day
	timeBlocks, err := getDayTimeBlocks(t.EndTime.Year, t.EndTime.Month, t.EndTime.Day)
	if err != nil {
		return err
	}

	if CheckNewOverlap(timeBlocks, t) {
		return fmt.Errorf("new time block overlaps with existing time block")
	}

	// Check if the file exists
	if _, err := os.Stat(t.EndTime.FileName()); os.IsNotExist(err) {
		// Create the file
		file, err := os.Create(t.EndTime.FileName())
		if err != nil {
			return err
		}
		defer file.Close()
	}

	// Take existing time blocks and append the new time block
	timeBlocks = append(timeBlocks, t)

	// Open the file for writing
	file, err := os.OpenFile(t.EndTime.FileName(), os.O_WRONLY, 0644)
	if err != nil {
		return err
	}
	defer file.Close()

	// Encode the time blocks into JSON and write to the file
	encoder := json.NewEncoder(file)
	err = encoder.Encode(timeBlocks)
	if err != nil {
		return err
	}

	return nil
}

func getDayTimeBlocks(year int, month int, day int) ([]TimeBlock, error) {
	var timeBlocks []TimeBlock
	//If the file does not exist, return an empty list
	if _, err := os.Stat(Time{year, month, day, 0, 0, 0}.FileName()); os.IsNotExist(err) {
		return timeBlocks, nil
	}

	// Open the file for reading
	file, err := os.OpenFile(Time{year, month, day, 0, 0, 0}.FileName(), os.O_RDONLY, 0644)
	if err != nil {
		return timeBlocks, err
	}
	defer file.Close()

	// Decode the JSON file into a list of time blocks
	decoder := json.NewDecoder(file)
	for decoder.More() {
		err := decoder.Decode(&timeBlocks)
		if err != nil {
			return timeBlocks, err
		}
	}

	// Check for overlaps
	if CheckOverlaps(timeBlocks) {
		var err = fmt.Errorf("overlapping time blocks")
		return timeBlocks, err
	}

	return timeBlocks, nil
}

func main() {
	var port string = "8080"
	if len(os.Args) > 1 {
		port = os.Args[1]
	}

	// Initialize the HTTP routes
	http.HandleFunc("/blocktypes", handleBlockTypes)
	http.HandleFunc("/timeblocks", handleTimeBlocks)
	http.HandleFunc("/currentblockname", handleCurrentBlockName)
	http.HandleFunc("/currentblocktype", handleCurrentBlockType)
	http.HandleFunc("/analysis", handleAnalysis)

	// Start the HTTP server
	fmt.Println("Server listening on port " + port + "...")
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

// Handler for retrieving all block types and creating a new block type
func handleBlockTypes(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		blockTypes, err := getBlockTypes()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			fmt.Println("GET /blocktypes - Internal server error")
			fmt.Println(err)
			return
		}
		// Return all block types
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(blockTypes)
		fmt.Println("GET /blocktypes")
	case http.MethodPost:
		// Create a new block type
		var newBlockType BlockType
		err := json.NewDecoder(r.Body).Decode(&newBlockType)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			fmt.Println("POST /blocktypes - Bad request")
			fmt.Println(err)
			fmt.Println(r.Body)
			fmt.Println(newBlockType)
			return
		}
		//Get all block types
		blockTypes, err := getBlockTypes()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			fmt.Println("POST /blocktypes - Internal server error")
			fmt.Println(err)
			return
		}
		// Assign a unique ID to the new block type
		newBlockType.ID = len(blockTypes)
		err = newBlockType.Save()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			fmt.Println("POST /blocktypes - Internal server error")
			fmt.Println(err)
			return
		}
		w.WriteHeader(http.StatusCreated)
		fmt.Println("POST /blocktypes")
	default:
		w.WriteHeader(http.StatusMethodNotAllowed)
	}
}

// Handler for retrieving time blocks for a specific day and creating a new time block
// Get: /timeblocks?year=2020&month=1&day=1
// Post: /timeblocks
func handleTimeBlocks(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		// Get the query parameters
		query := r.URL.Query()
		year := query.Get("year")
		month := query.Get("month")
		day := query.Get("day")

		// Return all time blocks for the specified day
		w.Header().Set("Content-Type", "application/json")
		l_year, _ := strconv.Atoi(year)
		l_month, _ := strconv.Atoi(month)
		l_day, _ := strconv.Atoi(day)
		timeBlocks, _ := getDayTimeBlocks(l_year, l_month, l_day)

		if timeBlocks == nil {
			timeBlocks = []TimeBlock{}
		}

		json.NewEncoder(w).Encode(timeBlocks)
		fmt.Println("GET /timeblocks?year=" + year + "&month=" + month + "&day=" + day)
	case http.MethodPost:
		// Create a new time block
		var newTimeBlock TimeBlock
		err := json.NewDecoder(r.Body).Decode(&newTimeBlock)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			fmt.Println("POST /timeblocks - Bad request")
			fmt.Println(err)
			fmt.Println(r.Body)
			fmt.Println(newTimeBlock)
			return
		}

		// Check if the start tiime is 1945/1/1 1:1:1
		// If so, set the start time to the endtime of the previous day's last time block
		reftime := Time{1945, 1, 1, 1, 1, 1}
		if newTimeBlock.StartTime == reftime {
			// Get the previous day's last time block
			previousDay := newTimeBlock.EndTime.getPreviousDay()
			previousDayTimeBlocks, _ := getDayTimeBlocks(previousDay.Year, previousDay.Month, previousDay.Day)
			if len(previousDayTimeBlocks) > 0 {
				newTimeBlock.StartTime = previousDayTimeBlocks[len(previousDayTimeBlocks)-1].EndTime

				// Save a time block for the previous day
				prevBlock := TimeBlock{
					StartTime: previousDayTimeBlocks[len(previousDayTimeBlocks)-1].EndTime,
					EndTime: Time{
						Year:   previousDay.Year,
						Month:  previousDay.Month,
						Day:    previousDay.Day,
						Hour:   23,
						Minute: 59,
						Second: 59,
					},
					BlockTypeID: newTimeBlock.BlockTypeID,
					Title:       newTimeBlock.Title,
				}
				prevBlock.Save()

				//Create a systemBlock for today
				systemBlock := TimeBlock{
					StartTime: Time{
						Year:   newTimeBlock.EndTime.Year,
						Month:  newTimeBlock.EndTime.Month,
						Day:    newTimeBlock.EndTime.Day,
						Hour:   0,
						Minute: 0,
						Second: 0,
					},
					EndTime: Time{
						Year:   newTimeBlock.EndTime.Year,
						Month:  newTimeBlock.EndTime.Month,
						Day:    newTimeBlock.EndTime.Day,
						Hour:   0,
						Minute: 0,
						Second: 0,
					},
					BlockTypeID: 0,
					Title:       "New Day",
				}

				systemBlock.Save()
				newTimeBlock.StartTime = Time{
					Year:   newTimeBlock.EndTime.Year,
					Month:  newTimeBlock.EndTime.Month,
					Day:    newTimeBlock.EndTime.Day,
					Hour:   0,
					Minute: 0,
					Second: 0,
				}
			} else {
				newTimeBlock.StartTime = newTimeBlock.EndTime
			}
		}

		// Save the new time block
		err = newTimeBlock.Save()
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			fmt.Println("POST /timeblocks - Bad request")
			fmt.Println(err)
			fmt.Println(r.Body)
			fmt.Println(newTimeBlock)
			return
		}

		w.WriteHeader(http.StatusCreated)
		fmt.Println("POST /timeblocks")
	default:
		w.WriteHeader(http.StatusMethodNotAllowed)
	}
}

func handleCurrentBlockName(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		// Get the current block name
		currentBlockName, err := getCurrentBlockName()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			fmt.Println("GET /currentblockname - Internal server error")
			fmt.Println(err)
			return
		}
		// Return the current block name
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(currentBlockName)
		fmt.Println("GET /currentblockname")
	case http.MethodPost:
		// Set the current block name
		var newCurrentBlockName string
		err := json.NewDecoder(r.Body).Decode(&newCurrentBlockName)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			fmt.Println("POST /currentblockname - Bad request")
			fmt.Println(err)
			fmt.Println(r.Body)
			fmt.Println(newCurrentBlockName)
			return
		}
		// Save the new current block name
		file, err := os.OpenFile("currentblockname.txt", os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0755)
		if err != nil {
			if os.IsNotExist(err) {
				file, err = os.Create("currentblockname.txt")
			} else {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				fmt.Println("POST /currentblockname - Internal server error")
				fmt.Println(err)
				return
			}
		}
		defer file.Close()

		_, err = file.WriteString(newCurrentBlockName)

		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			fmt.Println("POST /currentblockname - Internal server error")
			fmt.Println(err)
			return
		}
		w.WriteHeader(http.StatusCreated)
		fmt.Println("POST /currentblockname")
	default:
		w.WriteHeader(http.StatusMethodNotAllowed)
	}
}

func getCurrentBlockName() (string, error) {
	file, err := os.OpenFile("currentblockname.txt", os.O_RDWR, 0755)
	if err != nil {
		if os.IsNotExist(err) {
			file, err = os.Create("currentblockname.txt")
			if err != nil {
				return "", err
			}
			_, err = file.WriteString("Setting up server")
			return "Setting up server", err
		} else {
			return "", err
		}
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	scanner.Scan()
	return scanner.Text(), nil
}

func handleCurrentBlockType(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		// Get the current block type
		currentBlockType, err := getCurrentBlockType()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			fmt.Println("GET /currentblocktype - Internal server error")
			fmt.Println(err)
			return
		}
		// Return the current block type
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(currentBlockType)
		fmt.Println("GET /currentblocktype")
	case http.MethodPost:
		// Set the current block type
		var newCurrentBlockType int
		err := json.NewDecoder(r.Body).Decode(&newCurrentBlockType)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			fmt.Println("POST /currentblocktype - Bad request")
			fmt.Println(err)
			fmt.Println(r.Body)
			fmt.Println(newCurrentBlockType)
			return
		}
		// Save the new current block type
		file, err := os.OpenFile("currentblocktype.txt", os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0755)
		if err != nil {
			if os.IsNotExist(err) {
				file, err = os.Create("currentblocktype.txt")
			} else {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				fmt.Println("POST /currentblocktype - Internal server error")
				fmt.Println(err)
				return
			}
		}
		defer file.Close()

		_, err = file.WriteString(strconv.Itoa(newCurrentBlockType))

		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			fmt.Println("POST /currentblocktype - Internal server error")
			fmt.Println(err)
			return
		}

		w.WriteHeader(http.StatusCreated)
		fmt.Println("POST /currentblocktype")
	default:
		w.WriteHeader(http.StatusMethodNotAllowed)
	}
}

func getCurrentBlockType() (int, error) {
	file, err := os.OpenFile("currentblocktype.txt", os.O_RDWR, 0755)
	if err != nil {
		if os.IsNotExist(err) {
			file, err = os.Create("currentblocktype.txt")
			//Add zero to file
			_, err = file.WriteString("0")
			if err != nil {
				return 0, err
			}
			return 0, nil
		} else {
			return 0, err
		}
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	scanner.Scan()
	currentBlockType, err := strconv.Atoi(scanner.Text())
	if err != nil {
		return 0, err
	}
	return currentBlockType, nil
}

func handleAnalysis(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		// Get the analysis
		// Parse the query string
		query := r.URL.Query()

		startDay := query.Get("startday")
		startMonth := query.Get("startmonth")
		startYear := query.Get("startyear")
		endDay := query.Get("endday")
		endMonth := query.Get("endmonth")
		endYear := query.Get("endyear")

		l_startDay, err := strconv.Atoi(startDay)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			fmt.Println("GET /analysis - Bad request")
			fmt.Println(err)
			return
		}
		l_startMonth, err := strconv.Atoi(startMonth)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			fmt.Println("GET /analysis - Bad request")
			fmt.Println(err)
			return
		}
		l_startYear, err := strconv.Atoi(startYear)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			fmt.Println("GET /analysis - Bad request")
			fmt.Println(err)
			return
		}
		l_endDay, err := strconv.Atoi(endDay)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			fmt.Println("GET /analysis - Bad request")
			fmt.Println(err)
			return
		}
		l_endMonth, err := strconv.Atoi(endMonth)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			fmt.Println("GET /analysis - Bad request")
			fmt.Println(err)
			return
		}
		l_endYear, err := strconv.Atoi(endYear)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			fmt.Println("GET /analysis - Bad request")
			fmt.Println(err)
			return
		}

		startTime := Time{Day: l_startDay, Month: l_startMonth, Year: l_startYear, Hour: 0, Minute: 0, Second: 0}
		endTime := Time{Day: l_endDay, Month: l_endMonth, Year: l_endYear, Hour: 23, Minute: 59, Second: 59}

		analysis, err := getAnalysis(startTime, endTime)

		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			fmt.Println("GET /analysis - Internal server error")
			fmt.Println(err)
			return
		}

		// Send the analysis
		err = json.NewEncoder(w).Encode(analysis)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			fmt.Println("GET /analysis - Internal server error")
			fmt.Println(err)
			return
		}
		fmt.Println("GET /analysis")
	default:
		w.WriteHeader(http.StatusMethodNotAllowed)
	}
}

// Trend is the time spent on a block type for the duration
// Day holds the day
// TimeSpent holds the time spent on the block type on that day
type Trend struct {
	Day         Time     `json:"day"`
	TimeSpent   Duration `json:"timeSpent"`
	BlockTypeID int      `json:"blockTypeID"`
}

// Analysis is the analysis of the time spent on each block type
// for a given time period got from the query string
type Analysis struct {
	Percentages []float64 `json:"percentages"`
	Trends      []Trend   `json:"trends"`
}

// getAnalysis returns the analysis for the given time period
func getAnalysis(startTime Time, endTime Time) (Analysis, error) {
	// Get the blockTypes
	blockTypes, err := getBlockTypes()
	if err != nil {
		return Analysis{}, err
	}

	sort.Slice(blockTypes, func(i, j int) bool {
		return blockTypes[i].ID < blockTypes[j].ID
	})

	var analysis Analysis

	// Get the blocks
	for startTime.Before(endTime) {
		// Get the blocks for the day
		blocks, err := getDayTimeBlocks(startTime.Year, startTime.Month, startTime.Day)
		if err != nil {
			return Analysis{}, err
		}

		for _, blockType := range blockTypes {
			if blockType.ID == 0 {
				continue
			}
			var timeSpent Duration = Duration{Hour: 0, Minute: 0, Second: 0}
			for _, block := range blocks {
				if block.BlockTypeID == blockType.ID {
					timeSpent = timeSpent.Add(block.Duration())
				}
			}
			trendDay := Time{
				Day:    startTime.Day,
				Month:  startTime.Month,
				Year:   startTime.Year,
				Hour:   0,
				Minute: 0,
				Second: 0,
			}
			newTrend := Trend{Day: trendDay, TimeSpent: timeSpent, BlockTypeID: blockType.ID}
			analysis.Trends = append(analysis.Trends, newTrend)
		}

		startTime = startTime.Add(Duration{Hour: 24, Minute: 0, Second: 0})
	}

	// Compute the percentages from the trends for each block type

	// Step 1: Initialize a map to store the total time spent on each block type
	totalTimeByBlockType := make(map[int]Duration)

	// Step 2: Iterate over each trend and update the total time spent for each block type
	for _, trend := range analysis.Trends {
		totalTimeByBlockType[trend.BlockTypeID] = totalTimeByBlockType[trend.BlockTypeID].Add(trend.TimeSpent)
	}

	// Step 3: Calculate the total time spent across all block types
	totalDuration := Duration{Hour: 0, Minute: 0, Second: 0}
	for _, duration := range totalTimeByBlockType {
		totalDuration = totalDuration.Add(duration)
	}

	// Step 4: Initialize a slice to store the percentages of total time spent for each block type
	percentages := make([]float64, len(blockTypes))

	// Step 5: Iterate over block types and calculate the percentage of total time spent
	for i, blockType := range blockTypes {
		totalTime := totalTimeByBlockType[blockType.ID]
		percentage := float64(totalTime.toSeconds()) / float64(totalDuration.toSeconds()) * 100
		percentages[i] = percentage
	}

	analysis.Percentages = percentages

	return analysis, nil
}
