package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
)

type Time struct {
	Year   int `json:"year"`
	Month  int `json:"month"`
	Day    int `json:"day"`
	Hour   int `json:"hour"`
	Minute int `json:"minute"`
	Second int `json:"second"`
}

func (t Time) String() string {
	return fmt.Sprintf("%d-%02d-%02d %02d:%02d:%02d", t.Year, t.Month, t.Day, t.Hour, t.Minute, t.Second)
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

// BlockType represents the structure of a block type
type BlockType struct {
	ID    int    `json:"id"`
	Name  string `json:"name"`
	Color struct {
		H int `json:"h"`
		S int `json:"s"`
		V int `json:"v"`
	} `json:"color"`
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
		if blockType.Color.H == b.Color.H &&
			blockType.Color.S == b.Color.S &&
			blockType.Color.V == b.Color.V {
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
			_, err = file.WriteString("[]")
			if err != nil {
				return nil, err
			}
			return []BlockType{}, nil
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
	StartTime   Time `json:"startTime"`
	EndTime     Time `json:"endTime"`
	BlockTypeID int  `json:"blockTypeId"`
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
	timeBlocks, err := getDayTimeBlocks(t.StartTime.Year, t.StartTime.Month, t.StartTime.Day)
	if err != nil {
		return err
	}

	if CheckNewOverlap(timeBlocks, t) {
		return fmt.Errorf("new time block overlaps with existing time block")
	}

	// Check if the file exists
	if _, err := os.Stat(t.EndTime.FileName()); os.IsNotExist(err) {
		// Create the file
		file, err := os.Create(t.StartTime.FileName())
		if err != nil {
			return err
		}
		defer file.Close()
	}

	// Take existing time blocks and append the new time block
	timeBlocks = append(timeBlocks, t)

	// Open the file for writing
	file, err := os.OpenFile(t.StartTime.FileName(), os.O_WRONLY, 0644)
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
	// Initialize the HTTP routes
	http.HandleFunc("/blocktypes", handleBlockTypes)
	http.HandleFunc("/timeblocks", handleTimeBlocks)

	// Start the HTTP server
	fmt.Println("Server listening on port 8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
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
		newBlockType.ID = len(blockTypes) + 1
		err = newBlockType.Save()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			fmt.Println("POST /blocktypes - Internal server error")
			fmt.Println(err)
			return
		}
		w.WriteHeader(http.StatusCreated)
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
	default:
		w.WriteHeader(http.StatusMethodNotAllowed)
	}
}
